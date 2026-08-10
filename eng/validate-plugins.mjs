#!/usr/bin/env node

import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  AGENT_PLUGIN_SCHEMA_URL,
  COMPOSITION_NAMESPACE,
  COPILOT_NAMESPACE,
  REPOSITORY_URL,
  getComposition,
  listTopLevelResourceNames,
  readJson,
  readPluginEntries,
  resolveResource,
} from "./plugin-model.mjs";

const modulePath = fileURLToPath(import.meta.url);
const defaultRoot = resolve(dirname(modulePath), "..");
const SEMVER_PATTERN = /^\d+\.\d+\.\d+$/;
const KEYWORD_PATTERN = /^[a-z0-9-]+$/;
const COMPOSITION_FIELDS = new Set(["agents", "extensions", "skills"]);

function validateString(value, label, errors, { maxLength } = {}) {
  if (typeof value !== "string" || value.trim().length === 0) {
    errors.push(`${label} must be a non-empty string`);
  } else if (maxLength && value.length > maxLength) {
    errors.push(`${label} must not exceed ${maxLength} characters`);
  }
}

function validateReferences(root, entry, errors, referenced) {
  const composition = getComposition(entry.manifest);
  for (const field of Object.keys(composition)) {
    if (!COMPOSITION_FIELDS.has(field)) {
      errors.push(
        `${entry.directoryName}: unsupported ${COMPOSITION_NAMESPACE} field "${field}"`,
      );
    }
  }

  for (const kind of COMPOSITION_FIELDS) {
    const values = composition[kind] ?? [];
    if (!Array.isArray(values)) {
      errors.push(`${entry.directoryName}: ${kind} must be an array`);
      continue;
    }
    if (new Set(values).size !== values.length) {
      errors.push(`${entry.directoryName}: ${kind} references must be unique`);
    }
    const sorted = [...values].sort((left, right) =>
      left.localeCompare(right),
    );
    if (values.some((value, index) => value !== sorted[index])) {
      errors.push(`${entry.directoryName}: ${kind} references must be sorted`);
    }

    for (const reference of values) {
      const resource = resolveResource(
        root,
        entry.pluginDir,
        kind,
        reference,
      );
      if (!resource) {
        errors.push(
          `${entry.directoryName}: invalid ${kind} reference ${String(reference)}`,
        );
        continue;
      }
      if (!existsSync(resource.sourcePath)) {
        errors.push(
          `${entry.directoryName}: source not found for ${kind} reference ${reference}`,
        );
      }
      referenced[kind].add(resource.name);
    }
  }
}

function validateExtension(root, entry, errors) {
  const extensionDir = join(root, "extensions", entry.directoryName);
  if (!existsSync(extensionDir)) {
    return;
  }

  for (const requiredPath of [
    "extension.mjs",
    "package.json",
    "README.md",
    join("assets", "preview.png"),
  ]) {
    if (!existsSync(join(extensionDir, requiredPath))) {
      errors.push(
        `${entry.directoryName}: extension is missing ${requiredPath}`,
      );
    }
  }

  const extensionReferences = getComposition(entry.manifest).extensions ?? [];
  const expectedReference = `./extensions/${entry.directoryName}`;
  if (!extensionReferences.includes(expectedReference)) {
    errors.push(
      `${entry.directoryName}: standalone extension plugin must reference ${expectedReference}`,
    );
  }

  if (
    entry.manifest.extensions?.[COPILOT_NAMESPACE]?.logo !==
    "assets/preview.png"
  ) {
    errors.push(
      `${entry.directoryName}: ${COPILOT_NAMESPACE}.logo must be assets/preview.png`,
    );
  }

  const packagePath = join(extensionDir, "package.json");
  if (existsSync(packagePath)) {
    const packageJson = readJson(packagePath);
    if (packageJson.name !== entry.directoryName) {
      errors.push(
        `${entry.directoryName}: extension package name must match its folder`,
      );
    }
    if (packageJson.version !== entry.manifest.version) {
      errors.push(
        `${entry.directoryName}: extension package version must match its plugin`,
      );
    }
    if (packageJson.main !== "extension.mjs") {
      errors.push(
        `${entry.directoryName}: extension package main must be extension.mjs`,
      );
    }
    if (!packageJson.dependencies?.["@github/copilot-sdk"]) {
      errors.push(
        `${entry.directoryName}: extension package must depend on @github/copilot-sdk`,
      );
    }
  }
}

export function validatePlugins(root = defaultRoot) {
  const errors = [];
  const entries = readPluginEntries(root);
  const referenced = {
    agents: new Set(),
    extensions: new Set(),
    skills: new Set(),
  };

  for (const entry of entries) {
    const { manifest } = entry;
    if (!existsSync(join(entry.pluginDir, "README.md"))) {
      errors.push(`${entry.directoryName}: missing README.md`);
    }
    if (manifest.$schema !== AGENT_PLUGIN_SCHEMA_URL) {
      errors.push(
        `${entry.directoryName}: $schema must be ${AGENT_PLUGIN_SCHEMA_URL}`,
      );
    }
    if (manifest.name !== entry.directoryName) {
      errors.push(`${entry.directoryName}: name must match its folder`);
    }
    validateString(
      manifest.description,
      `${entry.directoryName}: description`,
      errors,
      { maxLength: 500 },
    );
    if (!SEMVER_PATTERN.test(manifest.version ?? "")) {
      errors.push(`${entry.directoryName}: version must use semantic versioning`);
    }
    if (manifest.repository !== REPOSITORY_URL) {
      errors.push(
        `${entry.directoryName}: repository must be ${REPOSITORY_URL}`,
      );
    }
    if (manifest.keywords !== undefined) {
      if (!Array.isArray(manifest.keywords)) {
        errors.push(`${entry.directoryName}: keywords must be an array`);
      } else {
        for (const keyword of manifest.keywords) {
          if (
            typeof keyword !== "string" ||
            !KEYWORD_PATTERN.test(keyword) ||
            keyword.length > 30
          ) {
            errors.push(
              `${entry.directoryName}: invalid keyword ${String(keyword)}`,
            );
          }
        }
      }
    }

    validateReferences(root, entry, errors, referenced);
    validateExtension(root, entry, errors);
  }

  for (const kind of Object.keys(referenced)) {
    for (const name of listTopLevelResourceNames(root, kind)) {
      if (!referenced[kind].has(name)) {
        errors.push(`${kind}/${name}: reusable source is not referenced`);
      }
      if (
        kind === "extensions" &&
        !entries.some((entry) => entry.directoryName === name)
      ) {
        errors.push(
          `extensions/${name}: matching standalone plugin is required`,
        );
      }
    }
  }

  return errors;
}

if (process.argv[1] && resolve(process.argv[1]) === modulePath) {
  const errors = validatePlugins(
    process.argv[2] ? resolve(process.argv[2]) : defaultRoot,
  );
  if (errors.length > 0) {
    console.error("Plugin validation failed:");
    for (const error of errors) {
      console.error(`- ${error}`);
    }
    process.exit(1);
  }
  console.log("All plugin manifests and reusable resources are valid.");
}
