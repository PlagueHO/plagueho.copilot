#!/usr/bin/env node

import { existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  readJson,
  readPluginEntries,
  writeJson,
} from "./plugin-model.mjs";

const modulePath = fileURLToPath(import.meta.url);
const defaultRoot = resolve(dirname(modulePath), "..");

export function generateMarketplace(root = defaultRoot) {
  const marketplacePath = join(
    root,
    ".github",
    "plugin",
    "marketplace.json",
  );
  if (!existsSync(marketplacePath)) {
    throw new Error(`Marketplace not found: ${marketplacePath}`);
  }

  const marketplace = readJson(marketplacePath);
  marketplace.name = "plagueho-copilot";
  marketplace.metadata.description =
    "Copilot plugins, skills, agents, and canvas extensions by Daniel Scott-Raynsford.";
  marketplace.metadata.version = "3.0.0";
  marketplace.plugins = readPluginEntries(root).map(
    ({ directoryName, manifest }) => ({
      name: manifest.name,
      source: directoryName,
      description: manifest.description,
      version: manifest.version,
    }),
  );

  writeJson(marketplacePath, marketplace);
  writeJson(
    join(root, ".claude-plugin", "marketplace.json"),
    marketplace,
  );

  console.log(
    `Generated marketplace with ${marketplace.plugins.length} plugin(s).`,
  );
  return marketplace;
}

if (process.argv[1] && resolve(process.argv[1]) === modulePath) {
  generateMarketplace(process.argv[2] ? resolve(process.argv[2]) : defaultRoot);
}
