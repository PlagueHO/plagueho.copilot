import assert from "node:assert/strict";
import { test } from "node:test";
import { mkdtemp, readFile, writeFile, rm, readdir } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import {
  applyUpdates, build, compareVersions, extractReferences, latest, references, restore,
} from "../skills/update-avm-modules/scripts/avm.mjs";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const scripts = join(root, "skills", "update-avm-modules", "scripts");
const fixtures = JSON.parse(await readFile(join(root, "tests", "update-avm-modules", "fixtures.json"), "utf8"));
const moduleName = "avm/res/storage/storage-account";
const source = `module storage 'br/public:${moduleName}:0.9.0' = {\n  params: {\n    oldParameter: true\n  }\n}\n`;

async function workspace(t, content = source) {
  const directory = await mkdtemp(join(tmpdir(), "avm-tests-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const file = join(directory, process.platform === "win32" ? "space and 'quoted'.bicep" : 'space and "quoted".bicep');
  await writeFile(file, content);
  return { directory, file, snapshot: join(directory, "snapshot.json") };
}

async function plan(file, extra = {}) {
  const [ref] = await references({ file });
  return [{ Module: ref.Module, OldVersion: ref.Version, NewVersion: "0.14.0",
    FilePath: file, FileHash: ref.FileHash, ...extra }];
}

for (const fixture of fixtures) {
  test(`shared parser: ${fixture.name}`, () => {
    if (fixture.error) {
      assert.throws(() => extractReferences(fixture.source, "test.bicep"), new RegExp(fixture.error));
    } else {
      assert.deepEqual(extractReferences(fixture.source, "test.bicep").map((ref) => ref.Version), fixture.versions);
    }
  });
}

test("numeric version tuples handle large components and reject invalid versions", () => {
  assert.equal(compareVersions("1.1000.0", "2.0.0"), -1);
  assert.equal(compareVersions("1.0.1000", "1.1.0"), -1);
  assert.equal(compareVersions("999999999999999999999.0.0", "2.0.0"), 1);
  for (const value of ["latest", "1.2", "1.2.03", "1.2.3-beta", "1.2.3+build"]) {
    assert.throws(() => compareVersions(value, "1.2.3"));
  }
});

test("latest queries once per module and preserves every file and version", async (t) => {
  const { file, directory } = await workspace(t, source + source.replaceAll("0.9.0", "0.10.0"));
  await writeFile(join(directory, "other.bicep"), source);
  let requests = 0;
  const results = await latest({ directory }, async (url) => {
    requests++;
    assert.equal(url, `https://mcr.microsoft.com/v2/bicep/${moduleName}/tags/list`);
    return { ok: true, json: async () => ({ tags: ["latest", "0.14.0-beta", "0.9.0", "0.14.0"] }) };
  });
  assert.equal(requests, 1);
  assert.equal(results.length, 3);
  assert.deepEqual(results.map((result) => result.Status), ["MINOR", "MINOR", "MINOR"]);
  assert.ok(results.some((result) => result.FilePath === file));
});

test("latest distinguishes current, ahead, and query failures", async (t) => {
  const { file } = await workspace(t);
  for (const [version, status] of [["0.9.0", "CURRENT"], ["0.8.0", "AHEAD"], ["0.9.1", "PATCH"], ["1.0.0", "MAJOR"]]) {
    const [result] = await latest({ file }, async () => ({ ok: true, json: async () => ({ tags: [version] }) }));
    assert.equal(result.Status, status);
  }
  for (const response of [
    { ok: false, status: 404 },
    { ok: true, json: async () => ({ tags: ["latest", "0.9.0-beta"] }) },
    { ok: true, json: async () => ({ tags: null }) },
  ]) {
    const [result] = await latest({ file }, async () => response);
    assert.equal(result.Status, "FAILED");
    assert.equal(result.Latest, null);
    assert.ok(result.Error);
  }
});

test("transient registry failures are retried with a bound", async (t) => {
  const { file } = await workspace(t);
  let attempts = 0;
  const [result] = await latest({ file }, async () => {
    attempts++;
    return { ok: false, status: 503 };
  });
  assert.equal(attempts, 3);
  assert.equal(result.Status, "FAILED");
});

test("updates preserve bytes outside declarations and restore parameter edits", async (t) => {
  const original = "\uFEFF" + ("// br/public:" + moduleName + ":0.9.0\n" + source).replaceAll("\n", "\r\n");
  const { file, snapshot, directory } = await workspace(t, original);
  const updates = await plan(file, { Edits: [{ OldText: "oldParameter: true", NewText: "newParameter: true" }] });
  await applyUpdates(updates, snapshot);
  const changed = await readFile(file, "utf8");
  assert.equal(changed, original.replace(`module storage 'br/public:${moduleName}:0.9.0'`,
    `module storage 'br/public:${moduleName}:0.14.0'`).replace("oldParameter", "newParameter"));
  assert.equal((await readdir(directory)).filter((name) => name.endsWith(".tmp")).length, 0);
  await restore(snapshot);
  assert.equal(await readFile(file, "utf8"), original);
  await restore(snapshot);
  assert.equal(await readFile(file, "utf8"), original);
});

test("preflight rejects stale, duplicate, missing, downgrade, and ambiguous operations", async (t) => {
  const { file, snapshot } = await workspace(t);
  const updates = await plan(file);
  const invalid = [
    [...updates, ...updates],
    [{ ...updates[0], NewVersion: "0.8.0" }],
    [{ ...updates[0], OldVersion: "0.8.0" }],
    [{ ...updates[0], FileHash: "0".repeat(64) }],
    [{ ...updates[0], Edits: [{ OldText: "missing", NewText: "new" }] }],
    [null],
  ];
  for (const update of invalid) {
    await assert.rejects(applyUpdates(update, snapshot));
    assert.equal(await readFile(file, "utf8"), source);
  }
  await assert.rejects(applyUpdates(updates));
  await writeFile(snapshot, "keep me");
  await assert.rejects(applyUpdates(updates, snapshot), /EEXIST/);
  assert.equal(await readFile(snapshot, "utf8"), "keep me");
});

test("all files are checked before the first write or restoration", async (t) => {
  const { file, directory, snapshot } = await workspace(t);
  const second = join(directory, "second.bicep");
  await writeFile(second, source);
  const updates = [...await plan(file), ...await plan(second)];
  await writeFile(second, source + "// concurrent\n");
  await assert.rejects(applyUpdates(updates, snapshot), /Stale/);
  assert.equal(await readFile(file, "utf8"), source);
  await writeFile(second, source);
  await applyUpdates(updates, snapshot);
  await writeFile(second, source + "// later edit\n");
  await assert.rejects(restore(snapshot), /Concurrent/);
  assert.ok((await readFile(file, "utf8")).includes(":0.14.0"));
  assert.ok((await readFile(second, "utf8")).includes("// later edit"));
});

test("updates distinguish complete versions and retain unaffected declarations", async (t) => {
  const content = source + source.replaceAll("0.9.0", "0.9.10").replace("storage ", "other ");
  const { file, snapshot } = await workspace(t, content);
  await applyUpdates(await plan(file), snapshot);
  const refs = await references({ file });
  assert.deepEqual(refs.map((ref) => ref.Version), ["0.14.0", "0.9.10"]);
  await restore(snapshot);
  assert.equal(await readFile(file, "utf8"), content);
});

test("restoration recovers a partly applied batch", async (t) => {
  const { file, directory, snapshot } = await workspace(t);
  const second = join(directory, "second.bicep");
  await writeFile(second, source);
  await applyUpdates([...await plan(file), ...await plan(second)], snapshot);
  await writeFile(second, source);
  await restore(snapshot);
  assert.equal(await readFile(file, "utf8"), source);
  assert.equal(await readFile(second, "utf8"), source);
});

test("tampered snapshots are rejected without changing targets", async (t) => {
  const { file, snapshot } = await workspace(t);
  await applyUpdates(await plan(file), snapshot);
  const saved = JSON.parse(await readFile(snapshot, "utf8"));
  saved.Files[0].Before = Buffer.from("tampered").toString("base64");
  await writeFile(snapshot, JSON.stringify(saved));
  await assert.rejects(restore(snapshot), /Invalid snapshot content/);
  assert.ok((await readFile(file, "utf8")).includes(":0.14.0"));
});

test("mixed registry failures do not discard successful references", async (t) => {
  const { file } = await workspace(t, source + source.replaceAll(moduleName, "avm/res/network/virtual-network"));
  const results = await latest({ file }, async (url) => url.includes("/network/")
    ? { ok: false, status: 404 }
    : { ok: true, json: async () => ({ tags: ["0.14.0"] }) });
  assert.deepEqual(results.map((result) => result.Status), ["MINOR", "FAILED"]);
});

test("build captures stdout and preserves adjacent JSON", async (t) => {
  const { directory } = await workspace(t);
  const file = join(directory, "main.bicep");
  const json = join(directory, "main.json");
  await writeFile(file, source);
  await writeFile(json, "existing template");
  const results = await build({ file }, (command, args, options) => {
    assert.ok(args.join(" ").includes("--stdout"));
    assert.equal(options.env.AVM_BUILD_FILE, file);
    assert.equal(options.windowsVerbatimArguments, process.platform === "win32");
    return { status: 0, stdout: '{"generated":true}', stderr: "" };
  });
  assert.equal(results[0].Status, "PASSED");
  assert.equal(await readFile(json, "utf8"), "existing template");
  assert.equal((await build({ file }, () => ({ status: 1, stderr: "parameter error" })))[0].Status, "FAILED");
  await assert.rejects(build({ files: [join(directory, "missing.bicep")] }), /ENOENT/);
});

test("optional installed Azure CLI builds paths with spaces without changing JSON",
  { skip: process.env.AVM_TEST_AZURE_CLI !== "1" }, async (t) => {
    const { file } = await workspace(t, "output message string = 'build smoke test'\n");
    const json = file.replace(/\.bicep$/, ".json");
    await writeFile(json, "existing template");
    const [result] = await build({ file });
    assert.equal(result.Status, "PASSED", result.Message);
    assert.equal(await readFile(json, "utf8"), "existing template");
  });

test("CLI returns arrays for empty, single and fatal results", async (t) => {
  const { file } = await workspace(t);
  for (const args of [["references", "--file", file], ["restore"], ["references", "--file", file, "--stdin"]]) {
    const result = spawnSync(process.execPath, [join(scripts, "avm.mjs"), ...args], { encoding: "utf8" });
    assert.ok(Array.isArray(JSON.parse(result.stdout)));
    assert.equal(result.status, args[0] === "references" && args.length === 3 ? 0 : 1);
  }
  await writeFile(file, "");
  const result = spawnSync(process.execPath, [join(scripts, "avm.mjs"), "references", "--file", file], { encoding: "utf8" });
  assert.equal(result.status, 0);
  assert.deepEqual(JSON.parse(result.stdout), []);
});

for (const platform of ["powershell", "bash"]) {
  test(`${platform} wrapper uses the shared discovery fixtures and transaction commands`, async (t) => {
    const command = platform === "powershell" ? "pwsh" : "bash";
    const probe = spawnSync(command, platform === "powershell" ? ["-NoProfile", "-Command", "exit 0"] : ["-c", "exit 0"]);
    if (probe.error) { t.skip(`${command} unavailable`); return; }
    const { file, directory, snapshot } = await workspace(t);
    function run(script, args) {
      const wrapper = join(scripts, script);
      return spawnSync(command, platform === "powershell" ? ["-NoProfile", "-File", wrapper, ...args] : [wrapper, ...args],
        { encoding: "utf8" });
    }
    for (const fixture of fixtures) {
      await writeFile(file, fixture.source);
      const result = run(platform === "powershell" ? "Get-AvmModuleReferences.ps1" : "get-avm-module-references.sh",
        [platform === "powershell" ? "-BicepFile" : "--file", file]);
      const rows = JSON.parse(result.stdout);
      assert.equal(result.status, fixture.error ? 1 : 0, result.stderr);
      if (!fixture.error) assert.deepEqual(rows.map((row) => row.Version), fixture.versions);
    }
    await writeFile(file, source);
    const updatesFile = join(directory, "plan.json");
    await writeFile(updatesFile, JSON.stringify(await plan(file)));
    const update = run(platform === "powershell" ? "Update-AvmVersions.ps1" : "update-avm-versions.sh",
      [platform === "powershell" ? "-UpdatesFile" : "--file", updatesFile,
        platform === "powershell" ? "-SnapshotFile" : "--snapshot-file", snapshot]);
    assert.equal(update.status, 0, update.stderr);
    assert.equal(JSON.parse(update.stdout)[0].Status, "UPDATED");
    const restored = run(platform === "powershell" ? "Restore-AvmVersions.ps1" : "restore-avm-versions.sh",
      [platform === "powershell" ? "-SnapshotFile" : "--snapshot-file", snapshot]);
    assert.equal(restored.status, 0, restored.stderr);
    assert.equal(await readFile(file, "utf8"), source);
  });
}
