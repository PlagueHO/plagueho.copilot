#!/usr/bin/env node
// Purpose: discover, compare, update, restore, and build AVM references.
// Usage: node avm.mjs <references|latest|update|restore|build> <options>
// Parameters: see references/REFERENCE.md. Requires Node.js 22+; no packages.
import { createHash, randomUUID } from "node:crypto";
import { readFile, readdir, realpath, writeFile, rename, unlink, lstat } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const versionPattern = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const modulePattern = /^avm\/(?:res|ptn|utl)\/[a-z0-9-]+(?:\/[a-z0-9-]+)*$/;
const hash = (bytes) => createHash("sha256").update(bytes).digest("hex");

export function compareVersions(left, right) {
  if (!versionPattern.test(left) || !versionPattern.test(right)) {
    throw new Error(`Expected stable MAJOR.MINOR.PATCH versions: ${left}, ${right}`);
  }
  const a = left.split(".").map(BigInt);
  const b = right.split(".").map(BigInt);
  for (let i = 0; i < 3; i++) {
    if (a[i] !== b[i]) return a[i] < b[i] ? -1 : 1;
  }
  return 0;
}

function decode(bytes) {
  const text = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(bytes);
  if (text.includes("\0")) throw new Error("Only UTF-8 Bicep files are supported.");
  return text;
}

// Tokenize instead of matching source text: comments and unrelated strings are not declarations.
export function extractReferences(text, filePath) {
  const tokens = [];
  let i = 0;
  while (i < text.length) {
    if (/\s/.test(text[i]) || text[i] === "\uFEFF") { i++; continue; }
    if (text.startsWith("//", i)) {
      const end = text.indexOf("\n", i);
      i = end < 0 ? text.length : end;
      continue;
    }
    if (text.startsWith("/*", i)) {
      const end = text.indexOf("*/", i + 2);
      if (end < 0) throw new Error(`Unclosed comment in ${filePath}`);
      i = end + 2;
      continue;
    }
    if (text.startsWith("'''", i)) {
      const end = text.indexOf("'''", i + 3);
      if (end < 0) throw new Error(`Unclosed multiline string in ${filePath}`);
      tokens.push({ value: text.slice(i + 3, end), kind: "multiline", start: i + 3 });
      i = end + 3;
      continue;
    }
    if (text[i] === "'") {
      const start = ++i;
      while (i < text.length && text[i] !== "'") {
        if (text[i] === "\\") i++;
        i++;
      }
      if (i === text.length) throw new Error(`Unclosed string in ${filePath}`);
      tokens.push({ value: text.slice(start, i), kind: "string", start });
      i++;
      continue;
    }
    const word = /^[A-Za-z_][A-Za-z0-9_]*/.exec(text.slice(i));
    tokens.push({ value: word ? word[0] : text[i], kind: word ? "word" : "symbol", start: i });
    i += word ? word[0].length : 1;
  }
  const results = [];
  for (let n = 0; n + 3 < tokens.length; n++) {
    const [keyword, name, path, equals] = tokens.slice(n, n + 4);
    if (keyword.kind !== "word" || keyword.value !== "module" || name.kind !== "word" ||
        path.kind !== "string" || equals.value !== "=") continue;
    if (!path.value.startsWith("br/public:avm/")) continue;
    const separator = path.value.lastIndexOf(":");
    const module = path.value.slice("br/public:".length, separator);
    const version = path.value.slice(separator + 1);
    if (!modulePattern.test(module) || !versionPattern.test(version)) {
      throw new Error(`Unsupported AVM reference in ${filePath}: ${path.value}`);
    }
    results.push({
      Module: module, Version: version, FilePath: filePath,
      LineNumber: text.slice(0, path.start).split("\n").length,
      Offset: path.start, Length: path.value.length,
    });
  }
  return results;
}

export async function targetFiles({ file, directory, files }) {
  const modes = [file !== undefined, directory !== undefined, files !== undefined].filter(Boolean).length;
  if (modes !== 1) throw new Error("Supply exactly one of --file, --directory, or --files.");
  let candidates = files ?? (file ? [file] : []);
  if (files && files.length === 0) throw new Error("--files requires at least one file.");
  if (directory) {
    candidates = [];
    async function walk(path) {
      const entries = await readdir(path, { withFileTypes: true });
      for (const entry of entries.sort((a, b) => a.name.localeCompare(b.name))) {
        const child = join(path, entry.name);
        if (entry.isDirectory()) await walk(child);
        else if (entry.isFile() && extname(child) === ".bicep") candidates.push(child);
      }
    }
    await walk(resolve(directory));
  }
  return [...new Set(await Promise.all(candidates.map(async (path) => {
    if (extname(path) !== ".bicep" || !(await lstat(path)).isFile()) {
      throw new Error(`Expected a regular .bicep file: ${path}`);
    }
    return realpath(path);
  })))].sort();
}

export async function references(options) {
  const results = [];
  for (const file of await targetFiles(options)) {
    const bytes = await readFile(file);
    results.push(...extractReferences(decode(bytes), file).map((ref) => ({ ...ref, FileHash: hash(bytes) })));
  }
  return results;
}

async function registryTags(module, fetcher) {
  const url = `https://mcr.microsoft.com/v2/bicep/${module}/tags/list`;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetcher(url, { signal: AbortSignal.timeout(15000), redirect: "error" });
      if (!response.ok) {
        if ((response.status === 429 || response.status >= 500) && attempt < 2) {
          await new Promise((done) => setTimeout(done, 250 * 2 ** attempt));
          continue;
        }
        throw new Error(`MCR HTTP ${response.status}`);
      }
      const body = await response.json();
      if (!Array.isArray(body.tags) || body.tags.some((tag) => typeof tag !== "string")) {
        throw new Error("Invalid MCR tags response.");
      }
      const stable = body.tags.filter((tag) => versionPattern.test(tag));
      if (!stable.length) throw new Error("No stable version tags found.");
      return stable.sort(compareVersions).at(-1);
    } catch (error) {
      if ((error.name === "TimeoutError" || error instanceof TypeError) && attempt < 2) {
        await new Promise((done) => setTimeout(done, 250 * 2 ** attempt));
        continue;
      }
      throw error;
    }
  }
}

export async function latest(options, fetcher = fetch) {
  const refs = await references(options);
  const cache = new Map();
  for (const { Module } of refs) {
    if (cache.has(Module)) continue;
    try {
      cache.set(Module, { Latest: await registryTags(Module, fetcher) });
    } catch (error) {
      cache.set(Module, { Latest: null, Error: error.message });
    }
  }
  return refs.map((ref) => {
    const result = cache.get(ref.Module);
    let Status = "FAILED";
    if (result.Latest) {
      const comparison = compareVersions(ref.Version, result.Latest);
      Status = comparison === 0 ? "CURRENT" : comparison > 0 ? "AHEAD" :
        ref.Version.split(".")[0] !== result.Latest.split(".")[0] ? "MAJOR" :
          ref.Version.split(".")[1] !== result.Latest.split(".")[1] ? "MINOR" : "PATCH";
    }
    return { ...ref, Current: ref.Version, ...result, Status };
  });
}

async function atomicReplace(file, bytes, expectedHash) {
  if (hash(await readFile(file)) !== expectedHash) throw new Error(`Concurrent edit: ${file}`);
  const temporary = `${file}.avm-${process.pid}-${randomUUID()}.tmp`;
  const mode = (await lstat(file)).mode;
  try {
    await writeFile(temporary, bytes, { flag: "wx", mode });
    if (hash(await readFile(file)) !== expectedHash) throw new Error(`Concurrent edit: ${file}`);
    await rename(temporary, file);
  } finally {
    await unlink(temporary).catch((error) => { if (error.code !== "ENOENT") throw error; });
  }
}

export async function applyUpdates(updates, snapshotFile) {
  if (!Array.isArray(updates)) throw new Error("Updates must be a JSON array.");
  if (!snapshotFile) throw new Error("--snapshot-file is required for safe rollback.");
  const grouped = new Map();
  for (const update of updates) {
    if (!update || typeof update !== "object" || !modulePattern.test(update.Module) ||
        !versionPattern.test(update.OldVersion) || !versionPattern.test(update.NewVersion) ||
        compareVersions(update.OldVersion, update.NewVersion) >= 0 ||
        typeof update.FileHash !== "string" || !/^[a-f0-9]{64}$/.test(update.FileHash)) {
      throw new Error("Each update needs a module, increasing stable versions, and the discovery FileHash.");
    }
    const [file] = await targetFiles({ file: update.FilePath });
    if (!grouped.has(file)) grouped.set(file, []);
    grouped.get(file).push(update);
  }
  const plans = [];
  for (const [file, operations] of grouped) {
    const original = await readFile(file);
    const beforeHash = hash(original);
    if (operations.some((operation) => operation.FileHash !== beforeHash)) {
      throw new Error(`Stale update plan: ${file}`);
    }
    let text = decode(original);
    const refs = extractReferences(text, file);
    const replacements = [];
    for (const operation of operations) {
      const matches = refs.filter((ref) => ref.Module === operation.Module && ref.Version === operation.OldVersion);
      if (!matches.length) throw new Error(`Reference not found: ${operation.Module}:${operation.OldVersion} in ${file}`);
      for (const ref of matches) {
        if (replacements.some((item) => item.start === ref.Offset)) throw new Error("Duplicate update operation.");
        replacements.push({ start: ref.Offset, length: ref.Length, value: `br/public:${ref.Module}:${operation.NewVersion}` });
      }
    }
    for (const replacement of replacements.sort((a, b) => b.start - a.start)) {
      text = text.slice(0, replacement.start) + replacement.value + text.slice(replacement.start + replacement.length);
    }
    for (const operation of operations) {
      if (operation.Edits !== undefined && !Array.isArray(operation.Edits)) throw new Error("Edits must be an array.");
      for (const edit of operation.Edits ?? []) {
        if (!edit || typeof edit.OldText !== "string" || !edit.OldText ||
            typeof edit.NewText !== "string" || text.split(edit.OldText).length !== 2) {
          throw new Error("Each approved parameter edit must match exactly once.");
        }
        if (/br\/public:avm\//.test(edit.OldText + edit.NewText)) {
          throw new Error("Use version operations, not parameter edits, for AVM references.");
        }
        text = text.replace(edit.OldText, () => edit.NewText);
      }
    }
    const after = Buffer.from(text, "utf8");
    plans.push({ FilePath: file, Before: original.toString("base64"), BeforeHash: beforeHash,
      AfterHash: hash(after), after });
  }
  const snapshot = { Version: 1, Files: plans.map(({ after, ...entry }) => entry) };
  const snapshotPath = resolve(snapshotFile);
  if (plans.some((plan) => plan.FilePath === snapshotPath)) throw new Error("Snapshot must be outside target files.");
  await writeFile(snapshotPath, `${JSON.stringify(snapshot, null, 2)}\n`, { flag: "wx", mode: 0o600 });
  for (const plan of plans) {
    await atomicReplace(plan.FilePath, plan.after, plan.BeforeHash);
  }
  return plans.map((plan) => ({ FilePath: plan.FilePath, Status: "UPDATED", SnapshotFile: snapshotPath }));
}

export async function restore(snapshotFile) {
  const snapshot = JSON.parse(await readFile(snapshotFile, "utf8"));
  if (!snapshot || snapshot.Version !== 1 || !Array.isArray(snapshot.Files)) throw new Error("Invalid snapshot.");
  const plans = [];
  for (const entry of snapshot.Files) {
    if (!entry || typeof entry.Before !== "string" || typeof entry.FilePath !== "string" ||
        !/^[a-f0-9]{64}$/.test(entry.BeforeHash) || !/^[a-f0-9]{64}$/.test(entry.AfterHash)) {
      throw new Error("Invalid snapshot entry.");
    }
    const [file] = await targetFiles({ file: entry.FilePath });
    if (plans.some((plan) => plan.file === file)) throw new Error("Duplicate snapshot file.");
    const bytes = Buffer.from(entry.Before, "base64");
    if (hash(bytes) !== entry.BeforeHash) throw new Error(`Invalid snapshot content: ${file}`);
    const current = hash(await readFile(file));
    if (current !== entry.BeforeHash && current !== entry.AfterHash) throw new Error(`Concurrent edit: ${file}`);
    plans.push({ file, bytes, current, beforeHash: entry.BeforeHash });
  }
  for (const plan of plans) {
    if (plan.current !== plan.beforeHash) await atomicReplace(plan.file, plan.bytes, plan.current);
  }
  return plans.map(({ file }) => ({ FilePath: file, Status: "RESTORED" }));
}

export async function build(options, runner = spawnSync) {
  const results = [];
  for (const file of await targetFiles(options)) {
    // az.cmd requires cmd.exe on Windows. Pass the path through an environment variable,
    // not interpolated shell input; reject cmd expansion characters in that path.
    if (process.platform === "win32" && /[%!\r\n"]/.test(file)) {
      throw new Error(`Unsupported Windows CLI path: ${file}`);
    }
    const command = process.platform === "win32" ? process.env.ComSpec ?? "cmd.exe" : "az";
    const args = process.platform === "win32"
      ? ["/d", "/s", "/c", 'az bicep build --file "%AVM_BUILD_FILE%" --stdout']
      : ["bicep", "build", "--file", file, "--stdout"];
    const result = runner(command, args, {
      encoding: "utf8", timeout: 120000, maxBuffer: 32 * 1024 * 1024,
      env: { ...process.env, AVM_BUILD_FILE: file }, windowsHide: true,
      windowsVerbatimArguments: process.platform === "win32",
    });
    results.push({ FilePath: file, Status: result.status === 0 && !result.error ? "PASSED" : "FAILED",
      Message: result.error?.message ?? (result.status === 0 ? "Build passed; deployment behavior not verified." :
        result.stderr?.trim() || `Build exited ${result.status}`) });
  }
  return results;
}

function parseOptions(args) {
  const options = {};
  const names = new Map([["--file", "file"], ["--directory", "directory"], ["--updates", "updates"],
    ["--snapshot-file", "snapshotFile"]]);
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--stdin") {
      if (options.stdin) throw new Error("Duplicate --stdin.");
      options.stdin = true;
    } else if (args[i] === "--files") {
      if (options.files) throw new Error("Duplicate --files.");
      options.files = [];
      while (i + 1 < args.length && !args[i + 1].startsWith("--")) options.files.push(args[++i]);
    } else {
      const key = names.get(args[i]);
      if (!key || options[key] !== undefined || !args[i + 1] || args[i + 1].startsWith("--")) {
        throw new Error(`Invalid or duplicate option: ${args[i]}`);
      }
      options[key] = args[++i];
    }
  }
  return options;
}

export async function main(args) {
  const [command, ...rest] = args;
  const options = parseOptions(rest);
  const allowed = {
    references: ["file", "directory", "files"],
    latest: ["file", "directory", "files"],
    build: ["file", "directory", "files"],
    update: ["file", "updates", "stdin", "snapshotFile"],
    restore: ["snapshotFile"],
  };
  if (!Object.hasOwn(allowed, command)) throw new Error("Expected references, latest, update, restore, or build.");
  if (Object.keys(options).some((key) => !allowed[command].includes(key))) {
    throw new Error(`Unsupported option for ${command}.`);
  }
  let results;
  if (command === "references") results = await references(options);
  else if (command === "latest") results = await latest(options);
  else if (command === "build") results = await build(options);
  else if (command === "restore") {
    if (!options.snapshotFile) throw new Error("--snapshot-file is required.");
    results = await restore(options.snapshotFile);
  } else if (command === "update") {
    if ([options.file !== undefined, options.updates !== undefined, options.stdin === true].filter(Boolean).length !== 1) {
      throw new Error("Supply exactly one of --file, --updates, or --stdin for updates.");
    }
    const input = options.file ? await readFile(options.file, "utf8") :
      options.stdin ? await new Promise((done, reject) => {
        let text = "";
        process.stdin.setEncoding("utf8").on("data", (chunk) => { text += chunk; }).on("end", () => done(text)).on("error", reject);
      }) : options.updates;
    results = await applyUpdates(JSON.parse(input), options.snapshotFile);
  } else throw new Error("Expected references, latest, update, restore, or build.");
  process.stdout.write(`${JSON.stringify(results)}\n`);
  if (results.some((result) => result.Status === "FAILED")) process.exitCode = 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.stdout.write(`${JSON.stringify([{ Status: "FAILED", Message: error.message }])}\n`);
    process.exitCode = 1;
  });
}
