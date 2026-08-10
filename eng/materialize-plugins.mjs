#!/usr/bin/env node

import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import {
  materializePlugin,
  readPluginEntries,
} from "./plugin-model.mjs";

const modulePath = fileURLToPath(import.meta.url);
const defaultRoot = resolve(dirname(modulePath), "..");

export function materializePlugins(root = defaultRoot) {
  const entries = readPluginEntries(root);
  let resourceCount = 0;

  for (const entry of entries) {
    const resources = materializePlugin(root, entry);
    resourceCount += resources.length;
    console.log(
      `Materialized ${entry.directoryName}: ${resources.length} resource(s)`,
    );
  }

  console.log(
    `Materialized ${resourceCount} resource(s) across ${entries.length} plugin(s).`,
  );
}

if (process.argv[1] && resolve(process.argv[1]) === modulePath) {
  materializePlugins(process.argv[2] ? resolve(process.argv[2]) : defaultRoot);
}
