import assert from "node:assert/strict";
import { test } from "node:test";
import { lstat, mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { checkSkills } from "../skills/review-agent-skills/scripts/check-frontmatter.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const scratchRoot = join(root, "eng");
const content = "---\nname: example\ndescription: Check casing.\n---\n# Example\n";

async function workspace(t) {
  const directory = await mkdtemp(join(scratchRoot, ".review-agent-skills-casing-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  return directory;
}

function check(result, id) {
  return result.results[0].checks.find((entry) => entry.ruleId === id);
}

async function casingError(input) {
  const result = await checkSkills([input]);
  assert.equal(result.exitCode, 2);
  assert.equal(result.results[0].executionError, true);
  assert.equal(check(result, "FM-008").state, "FAIL");
  return check(result, "FM-008").findings[0].message;
}

test("checker rejects a noncanonical stored entry filename for directory and file inputs", async (t) => {
  const workspacePath = await workspace(t);
  const directory = join(workspacePath, "example");
  await mkdir(directory);
  const storedFile = join(directory, "skill.md");
  await writeFile(storedFile, content);

  assert.match(await casingError(directory), /exactly SKILL\.md/);
  assert.match(await casingError(storedFile), /exactly SKILL\.md/);
  const incorrectlyCasedPath = join(directory, "SKILL.md");
  let caseInsensitiveLookup = true;
  try {
    await lstat(incorrectlyCasedPath);
  } catch (error) {
    if (error.code === "ENOENT") caseInsensitiveLookup = false;
    else throw error;
  }
  const wrongCaseMessage = await casingError(incorrectlyCasedPath);
  if (caseInsensitiveLookup) assert.match(wrongCaseMessage, /exactly SKILL\.md/);
});

test("FM-003 uses the stored directory name for directory and file inputs", async (t) => {
  const workspacePath = await workspace(t);
  const storedDirectory = join(workspacePath, "Example");
  await mkdir(storedDirectory);
  const file = join(storedDirectory, "SKILL.md");
  await writeFile(file, content);

  const directoryResult = await checkSkills([storedDirectory]);
  const fileResult = await checkSkills([file]);
  const directoryCheck = check(directoryResult, "FM-003");
  const fileCheck = check(fileResult, "FM-003");
  assert.equal(directoryCheck.state, "FAIL");
  assert.deepEqual(fileCheck, directoryCheck);
  assert.equal(directoryResult.results[0].skill, "Example");

  let caseAliasExists = true;
  try {
    await lstat(join(workspacePath, "example"));
  } catch (error) {
    if (error.code === "ENOENT") caseAliasExists = false;
    else throw error;
  }
  if (caseAliasExists) {
    const aliasDirectory = join(workspacePath, "example");
    const aliasDirectoryResult = await checkSkills([aliasDirectory]);
    const aliasFileResult = await checkSkills([join(aliasDirectory, "SKILL.md")]);
    assert.equal(check(aliasDirectoryResult, "FM-003").state, "FAIL");
    assert.deepEqual(check(aliasFileResult, "FM-003"), directoryCheck);
    assert.equal(aliasDirectoryResult.results[0].skill, "Example");
  }
});
