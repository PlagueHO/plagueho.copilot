import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { createInstallLinks } from "../website/install-links.mjs";

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const marketplaceSource = "PlagueHO/plagueho.copilot#marketplace";
const affectedPlugins = [
  "azure-infrastructure-deployment",
  "content-and-learning",
  "developer-environment",
  "dotnet-modernization",
  "github-workflows",
  "powershell-modernization",
  "skill-lifecycle",
  "suggest-awesome-github-copilot",
];

function* guidanceFiles(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      if (!["node_modules", "dist", ".astro", "public"].includes(entry.name)) {
        yield* guidanceFiles(path);
      }
    } else if (entry.isFile() && /\.(mdx?|astro)$/.test(entry.name)) {
      yield path;
    }
  }
}

test("plugin and extension README commands use this marketplace", () => {
  const readmes = affectedPlugins.map((name) => [
    join(root, "plugins", name, "README.md"),
    name,
  ]);
  readmes.push([
    join(root, "extensions", "windows-app-storage-inspector-cleanup", "README.md"),
    "windows-app-storage-inspector-cleanup",
  ]);

  for (const [path, name] of readmes) {
    const readme = readFileSync(path, "utf8");
    assert.ok(
      readme.includes(`copilot plugin install ${name}@plagueho-copilot`),
      path,
    );
  }
});

test("documentation contains no obsolete installation or branchless registration commands", () => {
  const paths = readdirSync(root, { withFileTypes: true })
    .filter((entry) => entry.isFile() && /\.mdx?$/.test(entry.name))
    .map((entry) => join(root, entry.name));
  for (const directory of [
    ".github", "agents", "docs", "extensions", "plugins", "skills", "website",
  ]) {
    paths.push(...guidanceFiles(join(root, directory)));
  }

  let registrationCount = 0;
  for (const path of paths) {
    const content = readFileSync(path, "utf8");
    for (const [, source] of content.matchAll(
      /(?:copilot plugin|\/plugin)\s+install\s+([^\s`"'<>]+)/g,
    )) {
      assert.doesNotMatch(
        source,
        /@(?:plagueho-os|plagueho-agent-skills)\b/,
        path,
      );
    }
    for (const [, source] of content.matchAll(
      /(?:copilot plugin|\/plugin)\s+marketplace\s+add\s+([^\s`"'<>]+)/g,
    )) {
      if (/^PlagueHO\/plagueho\.copilot(?:#|$)/i.test(source)) {
        assert.equal(source, marketplaceSource, path);
        registrationCount++;
      }
    }
  }
  assert.ok(registrationCount >= 2, "Expected the documented registration examples");
});

for (const pluginName of ["github-workflows", "windows-app-storage-inspector-cleanup"]) {
  test(`website installation values target the published marketplace for ${pluginName}`, () => {
    const links = createInstallLinks(pluginName);
    const pluginSource = `${pluginName}@plagueho-copilot`;
    assert.equal(links.pluginName, pluginName);
    assert.equal(links.marketplaceName, "plagueho-copilot");
    assert.equal(links.marketplaceSource, marketplaceSource);
    assert.equal(
      links.marketplaceAddCommand,
      `copilot plugin marketplace add ${marketplaceSource}`,
    );
    assert.equal(links.installCommand, `copilot plugin install ${pluginSource}`);
    assert.equal(
      links.directInstallUrl,
      `https://github.com/PlagueHO/plagueho.copilot/tree/marketplace/plugins/${pluginName}`,
    );

    for (const [field, pathname, source] of [
      ["marketplaceAddUrl", "/marketplace/add", marketplaceSource],
      ["copilotAppInstallUrl", "/install", pluginSource],
    ]) {
      const launcher = new URL(links[field]);
      assert.equal(launcher.origin, "https://github.com");
      assert.equal(launcher.pathname, "/copilot/app/launch");
      const appLink = new URL(launcher.searchParams.get("open"));
      assert.equal(appLink.protocol, "ghapp:");
      assert.equal(appLink.hostname, "plugins");
      assert.equal(appLink.pathname, pathname);
      assert.equal(appLink.searchParams.get("source"), source);
      assert.equal(appLink.hash, "");
    }

    for (const [field, protocol] of [
      ["vscodeInstallUrl", "vscode:"],
      ["vscodeInsidersInstallUrl", "vscode-insiders:"],
    ]) {
      const url = new URL(links[field]);
      assert.equal(url.protocol, protocol);
      assert.equal(url.hostname, "chat-plugin");
      assert.equal(url.pathname, "/install");
      assert.equal(url.searchParams.get("source"), marketplaceSource);
      assert.equal(url.searchParams.get("plugin"), pluginName);
      assert.equal(url.hash, "");
    }
  });
}

test("extension listing fallback and settings instructions use the published branch", () => {
  const page = readFileSync(
    join(root, "website", "src", "pages", "extensions.astro"),
    "utf8",
  );
  assert.ok(page.includes(`marketplaceSource ?? '${marketplaceSource}'`));
  assert.ok(page.includes(`add <code>${marketplaceSource}</code>`));
});

test("home page registration links, settings, and copy buttons use the published branch", () => {
  const page = readFileSync(
    join(root, "website", "src", "pages", "index.astro"),
    "utf8",
  );
  const links = [...page.matchAll(
    /href="(vscode(?:-insiders)?:\/\/settings\/chat\.plugins\.marketplaces[^"]+)"/g,
  )];
  assert.equal(links.length, 2);
  for (const [, href] of links) {
    const url = new URL(href);
    assert.equal(url.searchParams.get("install-extension"), marketplaceSource);
    assert.equal(url.hash, "");
  }
  assert.ok(page.includes(
    `<code class="install__code">/plugin marketplace add ${marketplaceSource}</code>`,
  ));
  assert.ok(page.includes(`data-copy="/plugin marketplace add ${marketplaceSource}"`));
  const setting = `"chat.plugins.marketplaces": ["${marketplaceSource}"]`;
  assert.ok(page.includes(`<code class="install__code">${setting}</code>`));
  assert.ok(page.includes(`data-copy='${setting}'`));
});
