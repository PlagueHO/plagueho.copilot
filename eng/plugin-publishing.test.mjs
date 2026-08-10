import assert from "node:assert/strict";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";
import { tmpdir } from "node:os";
import { mkdtempSync } from "node:fs";
import {
  AGENT_PLUGIN_SCHEMA_URL,
  createServedManifest,
  materializePlugin,
  readPluginEntries,
} from "./plugin-model.mjs";
import { validatePlugins } from "./validate-plugins.mjs";

function writeJson(path, value) {
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function createFixture() {
  const root = mkdtempSync(join(tmpdir(), "plagueho-copilot-"));
  const pluginDir = join(root, "plugins", "sample");
  const skillDir = join(root, "skills", "sample-skill");
  mkdirSync(pluginDir, { recursive: true });
  mkdirSync(skillDir, { recursive: true });
  writeFileSync(join(pluginDir, "README.md"), "# Sample\n");
  writeFileSync(
    join(skillDir, "SKILL.md"),
    "---\nname: sample-skill\ndescription: Sample skill.\n---\n",
  );
  writeJson(join(pluginDir, "plugin.json"), {
    $schema: AGENT_PLUGIN_SCHEMA_URL,
    name: "sample",
    description: "Sample plugin.",
    version: "1.0.0",
    repository: "https://github.com/PlagueHO/plagueho.copilot",
    extensions: {
      "com.github.plagueho": {
        skills: ["./skills/sample-skill/"],
      },
    },
  });
  return { pluginDir, root };
}

test("source manifests validate and materialize conventional plugin content", () => {
  const { pluginDir, root } = createFixture();
  assert.deepEqual(validatePlugins(root), []);

  const [entry] = readPluginEntries(root);
  materializePlugin(root, entry);

  assert.equal(
    readFileSync(
      join(pluginDir, "skills", "sample-skill", "SKILL.md"),
      "utf8",
    ).includes("sample-skill"),
    true,
  );
  const served = JSON.parse(
    readFileSync(join(pluginDir, "plugin.json"), "utf8"),
  );
  assert.equal(served.extensions, undefined);
});

test("served manifests retain client data and remove build composition", () => {
  const served = createServedManifest({
    name: "sample",
    extensions: {
      "com.github.copilot": { logo: "assets/preview.png" },
      "com.github.plagueho": {
        extensions: ["./extensions/sample"],
      },
    },
  });

  assert.deepEqual(served.extensions, {
    "com.github.copilot": { logo: "assets/preview.png" },
  });
});

test("extension plugins materialize source and preview assets", () => {
  const root = mkdtempSync(join(tmpdir(), "plagueho-copilot-extension-"));
  const pluginDir = join(root, "plugins", "sample-extension");
  const extensionDir = join(root, "extensions", "sample-extension");
  mkdirSync(join(extensionDir, "assets"), { recursive: true });
  mkdirSync(pluginDir, { recursive: true });
  writeFileSync(join(pluginDir, "README.md"), "# Sample Extension\n");
  writeFileSync(join(extensionDir, "README.md"), "# Sample Extension\n");
  writeFileSync(join(extensionDir, "extension.mjs"), "export default {};\n");
  writeFileSync(join(extensionDir, "assets", "preview.png"), "preview");
  writeJson(join(extensionDir, "package.json"), {
    name: "sample-extension",
    version: "1.0.0",
    type: "module",
    main: "extension.mjs",
    dependencies: {
      "@github/copilot-sdk": "1.0.0",
    },
  });
  writeJson(join(pluginDir, "plugin.json"), {
    $schema: AGENT_PLUGIN_SCHEMA_URL,
    name: "sample-extension",
    description: "Sample canvas extension.",
    version: "1.0.0",
    repository: "https://github.com/PlagueHO/plagueho.copilot",
    extensions: {
      "com.github.copilot": { logo: "assets/preview.png" },
      "com.github.plagueho": {
        extensions: ["./extensions/sample-extension"],
      },
    },
  });

  assert.deepEqual(validatePlugins(root), []);
  materializePlugin(root, readPluginEntries(root)[0]);

  assert.equal(
    readFileSync(
      join(
        pluginDir,
        "extensions",
        "sample-extension",
        "extension.mjs",
      ),
      "utf8",
    ),
    "export default {};\n",
  );
  assert.equal(
    readFileSync(join(pluginDir, "assets", "preview.png"), "utf8"),
    "preview",
  );
});
