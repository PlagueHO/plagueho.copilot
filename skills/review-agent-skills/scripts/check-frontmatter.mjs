#!/usr/bin/env node
// Purpose: validate untrusted skill frontmatter; never execute target contents.
// Parameters: [--profile standard|catalog] -- PATH [PATH...]
// Usage: node check-frontmatter.mjs --profile catalog -- ./skills/example
// Requires Node.js 20+ and the yaml dependency from this directory's package.json.
import { lstat, open, realpath } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const maxFileBytes = 5 * 1024 * 1024;
const maxFrontmatterBytes = 64 * 1024;
const standardFields = new Set(["name", "description", "license", "compatibility", "metadata", "allowed-tools"]);
const localFields = new Set([...standardFields, "argument-hint", "user-invocable"]);
const definitions = [
  ["FM-001", "Skill best practices", "high", "standard"],
  ["FM-002", "Skill best practices", "high", "standard"],
  ["FM-003", "Skill best practices", "high", "standard"],
  ["FM-004", "Skill best practices", "high", "standard"],
  ["FM-005", "Skill best practices", "medium", "standard"],
  ["FM-006", "Agentic portability", "medium", "standard"],
  ["FM-007", "Reliability", "high", "quality"],
  ["FM-008", "Structure", "high", "standard"],
  ["FM-009", "Reliability", "high", "quality"],
  ["LC-001", "Skill best practices", "medium", "local"],
  ["LC-002", "Agentic portability", "high", "local"],
  ["LC-003", "Skill best practices", "medium", "local"],
];
const length = (value) => [...value].length;
const nonemptyString = (value) => typeof value === "string" && value.trim().length > 0;

export async function loadYaml() {
  try {
    return await import("yaml");
  } catch (error) {
    if (error.code === "ERR_MODULE_NOT_FOUND") {
      throw new Error("Missing YAML dependency. Install dependencies in the checker's scripts directory through an approved package source. No checks ran.");
    }
    throw error;
  }
}

function createResult(skill, profile) {
  return {
    skill,
    file: "SKILL.md",
    executionError: false,
    checks: definitions.filter(([id]) => profile === "catalog" || !id.startsWith("LC-")).map(
      ([ruleId, category, severity, basis]) => ({
        ruleId, category, severity, basis, state: "NOT_CHECKED", findings: [],
      }),
    ),
  };
}

function record(result, id, findings = [], applicable = true) {
  const check = result.checks.find((entry) => entry.ruleId === id);
  if (!check) return;
  check.state = !applicable ? "NOT_APPLICABLE" : findings.length ? "FAIL" : "PASS";
  check.findings = findings;
}

function finding(message, line = 1, endLine = line) {
  return { file: "SKILL.md", line, endLine, message };
}

async function assertUnlinked(path) {
  for (let current = path; ; current = dirname(current)) {
    if ((await lstat(current)).isSymbolicLink()) {
      throw new Error("Linked target paths are outside the checker boundary.");
    }
    if (dirname(current) === current) return;
  }
}

async function readTarget(input) {
  const path = resolve(input);
  await assertUnlinked(path);
  const stat = await lstat(path);
  const directory = stat.isDirectory() ? path : dirname(path);
  const file = stat.isDirectory() ? join(path, "SKILL.md") : path;
  if (basename(file) !== "SKILL.md") throw new Error("Supply a skill directory or a file named SKILL.md.");
  await assertUnlinked(file);
  if (!(await lstat(file)).isFile()) throw new Error("SKILL.md must be a regular file.");
  return { directory, file, canonical: await realpath(file) };
}

async function readBounded(file) {
  const handle = await open(file, "r");
  try {
    const bytes = Buffer.alloc(maxFileBytes + 1);
    let total = 0;
    while (total < bytes.length) {
      const { bytesRead } = await handle.read(bytes, total, bytes.length - total, null);
      if (!bytesRead) break;
      total += bytesRead;
    }
    if (total > maxFileBytes) return { limit: true };
    return { text: new TextDecoder("utf-8", { fatal: true }).decode(bytes.subarray(0, total)) };
  } finally {
    await handle.close();
  }
}

function frontmatter(text) {
  const lines = text.split(/\r?\n/);
  if (lines[0] !== "---") return { error: finding("Start SKILL.md with a YAML frontmatter delimiter (---).") };
  const end = lines.indexOf("---", 1);
  if (end < 0) return { error: finding("Close YAML frontmatter with a delimiter (---).") };
  return { source: lines.slice(1, end).join("\n") + "\n" };
}

function checkDocument(result, source, directoryName, yaml) {
  const lineCounter = new yaml.LineCounter();
  const document = yaml.parseDocument(source, { lineCounter, uniqueKeys: true, strict: true, version: "1.2" });
  const line = (node) => lineCounter.linePos(node?.range?.[0] ?? 0).line + 1;
  const exhausted = document.errors.filter((error) => error.code === "RESOURCE_EXHAUSTION");
  if (exhausted.length) {
    record(result, "FM-009", exhausted.map((error) => finding(
      "YAML nesting exhausted parser resources. Simplify the frontmatter and rerun.",
      lineCounter.linePos(error.pos[0]).line + 1,
    )));
    return;
  }
  const hazards = [];
  yaml.visit(document, {
    Node(_key, node) {
      if (node.tag || node.anchor || yaml.isAlias(node)) {
        hazards.push(finding("Use explicit plain values; tags, anchors, and aliases are not supported.", line(node)));
      }
      if (yaml.isMap(node)) {
        for (const pair of node.items) {
          if (yaml.isScalar(pair.key) && pair.key.value === "<<") {
            hazards.push(finding("Merge keys are not supported.", line(pair.key)));
          }
        }
      }
    },
  });
  for (const error of document.errors) {
    if (error.code === "DUPLICATE_KEY") {
      hazards.push(finding("Duplicate mapping keys are not supported.", lineCounter.linePos(error.pos[0]).line + 1));
    }
  }
  record(result, "FM-007", hazards);
  const syntax = [...document.errors, ...document.warnings].map(
    (error) => finding(`Invalid or unsupported YAML (${error.code}).`, lineCounter.linePos(error.pos[0]).line + 1),
  );
  if (!yaml.isMap(document.contents)) syntax.push(finding("Frontmatter must be one YAML mapping.", 2));
  record(result, "FM-001", syntax);
  if (syntax.length || hazards.length) return;

  const values = document.toJS({ mapAsMap: true, maxAliasCount: 0 });
  const keyLine = (key) => line(document.contents.items.find((pair) => pair.key?.value === key)?.key);
  const at = (key, message) => finding(message, keyLine(key));
  const name = values.get("name");
  const description = values.get("description");
  record(result, "FM-002", ["name", "description"].filter((key) => !nonemptyString(values.get(key)))
    .map((key) => at(key, `Provide a non-empty string ${key} field.`)));
  if (nonemptyString(name)) {
    const validName = length(name) <= 64 && /^[\p{L}\p{N}]+(?:-[\p{L}\p{N}]+)*$/u.test(name) &&
      name === name.toLowerCase() && name === directoryName;
    record(result, "FM-003", validName ? [] : [
      at("name", "Use a 1-64 character lowercase alphanumeric/hyphen name that exactly matches the directory; do not use repeated or edge hyphens."),
    ]);
    record(result, "LC-001", /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name) ? [] : [
      at("name", "The catalog name convention permits ASCII lowercase letters, digits, and hyphens only."),
    ]);
  }
  if (nonemptyString(description)) {
    record(result, "FM-004", length(description) <= 1024 ? [] : [
      at("description", "Keep the decoded description at or below 1024 Unicode characters."),
    ]);
  }
  const optional = [];
  for (const key of ["license", "allowed-tools"]) {
    if (values.has(key) && typeof values.get(key) !== "string") optional.push(at(key, `Use a string ${key} field.`));
  }
  const compatibility = values.get("compatibility");
  if (values.has("compatibility") && (!nonemptyString(compatibility) || length(compatibility) > 500)) {
    optional.push(at("compatibility", "Use a non-empty compatibility string of at most 500 Unicode characters."));
  }
  const metadata = values.get("metadata");
  if (values.has("metadata") && (!(metadata instanceof Map) ||
      [...metadata].some(([key, value]) => typeof key !== "string" || typeof value !== "string"))) {
    optional.push(at("metadata", "Use a metadata mapping with string keys and string values."));
  }
  record(result, "FM-005", optional, ["license", "allowed-tools", "compatibility", "metadata"].some((key) => values.has(key)));
  const keys = [...values.keys()];
  record(result, "FM-006", keys.filter((key) => !standardFields.has(key))
    .map((key) => at(key, "This top-level field is not defined by the Agent Skills standard.")));
  record(result, "LC-002", values.has("allowed-tools") ? [
    at("allowed-tools", "The catalog policy does not permit allowed-tools, although it is experimental in the standard."),
  ] : []);
  const local = keys.filter((key) => !localFields.has(key))
    .map((key) => at(key, "This top-level field is not part of the selected catalog convention."));
  for (const [key, type] of [["argument-hint", "string"], ["user-invocable", "boolean"]]) {
    if (values.has(key) && typeof values.get(key) !== type) local.push(at(key, `Use a ${type} ${key} field under the catalog convention.`));
  }
  if (values.has("compatibility")) {
    const valid = nonemptyString(compatibility) && length(compatibility) <= 500 ||
      Array.isArray(compatibility) && compatibility.length > 0 && compatibility.every(nonemptyString);
    if (!valid) local.push(at("compatibility", "Use a compatibility string of 1-500 characters or a non-empty list of environment strings locally."));
  }
  record(result, "LC-003", local);
}

export async function checkSkills(inputs, { profile = "standard", yaml } = {}) {
  if (!["standard", "catalog"].includes(profile)) throw new Error("Use profile standard or catalog.");
  if (!Array.isArray(inputs) || inputs.length === 0 || inputs.length > 64 ||
      inputs.some((input) => typeof input !== "string" || !input.trim())) {
    throw new Error("Supply 1-64 explicit skill directories or SKILL.md paths. No target is inferred.");
  }
  yaml ??= await loadYaml();
  const results = [];
  const seen = new Set();
  for (const input of inputs) {
    let target;
    try {
      target = await readTarget(input);
    } catch (error) {
      const result = createResult(basename(resolve(input)), profile);
      result.executionError = true;
      record(result, "FM-008", [finding(
        ["ENOENT", "ENOTDIR", "EACCES", "EPERM"].includes(error.code)
          ? `Target is missing or unreadable (${error.code}).` : error.message,
      )]);
      results.push(result);
      continue;
    }
    if (seen.has(target.canonical)) continue;
    seen.add(target.canonical);
    const result = createResult(basename(target.directory), profile);
    results.push(result);
    record(result, "FM-008");
    let read;
    try {
      read = await readBounded(target.file);
    } catch (error) {
      if (error.code === "ERR_ENCODING_INVALID_ENCODED_DATA") {
        record(result, "FM-001", [finding("SKILL.md must contain valid UTF-8 text.")]);
      } else {
        result.executionError = true;
        record(result, "FM-008", [finding("SKILL.md could not be read. Check access and rerun.")]);
      }
      continue;
    }
    if (read.limit) {
      record(result, "FM-009", [finding("SKILL.md exceeds the checker limit of 5 MiB.")]);
      continue;
    }
    const parsed = frontmatter(read.text);
    if (parsed.error) {
      record(result, "FM-009");
      record(result, "FM-001", [parsed.error]);
      continue;
    }
    if (Buffer.byteLength(parsed.source, "utf8") > maxFrontmatterBytes) {
      record(result, "FM-009", [finding("Frontmatter exceeds the checker limit of 64 KiB.", 2)]);
      continue;
    }
    record(result, "FM-009");
    checkDocument(result, parsed.source, basename(target.directory), yaml);
  }
  const exitCode = results.some((result) => result.executionError) ? 2 :
    results.some((result) => result.checks.some((check) => check.state === "FAIL")) ? 1 : 0;
  return { schemaVersion: 1, profile, exitCode, results };
}

export async function main(args) {
  try {
    let profile = "standard";
    if (args[0] === "--profile") {
      profile = args[1];
      args = args.slice(2);
      if (!profile) throw new Error("A profile value is required.");
    }
    if (args[0] === "--") args = args.slice(1);
    else if (args.some((arg) => arg.startsWith("--"))) throw new Error("Unknown option. Use [--profile standard|catalog] -- PATH [PATH...].");
    const result = await checkSkills(args, { profile });
    console.log(JSON.stringify(result, null, 2));
    return result.exitCode;
  } catch (error) {
    const message = error instanceof Error ? error.message : "The checker failed. No success result is available.";
    console.error(message);
    console.log(JSON.stringify({ schemaVersion: 1, exitCode: 2, results: [], error: message }, null, 2));
    return 2;
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = await main(process.argv.slice(2));
}
