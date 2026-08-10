#!/usr/bin/env node

import {
  cpSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { marked } from "marked";

const websiteDir = dirname(fileURLToPath(import.meta.url));
const root = join(websiteDir, "..");
const dataDir = join(websiteDir, "public", "data");
const previewDir = join(websiteDir, "public", "extension-previews");
const compositionNamespace = "com.github.plagueho";
const githubBase = "https://github.com/PlagueHO/plagueho.copilot";

mkdirSync(dataDir, { recursive: true });
mkdirSync(previewDir, { recursive: true });

function readJson(path) {
  return JSON.parse(readFileSync(path, "utf8"));
}

function parseScalar(value) {
  const trimmed = value.trim().replace(/^["']|["']$/g, "");
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
    return trimmed
      .slice(1, -1)
      .split(",")
      .map((item) => item.trim().replace(/^["']|["']$/g, ""))
      .filter(Boolean);
  }
  return trimmed;
}

function parseFrontmatterFields(content) {
  const match = content.match(/^---\s*\n([\s\S]*?)\n---/);
  if (!match) return {};

  const lines = match[1].split("\n");
  const result = {};
  let index = 0;

  while (index < lines.length) {
    const topLevel = lines[index].match(
      /^([a-zA-Z][a-zA-Z0-9-]*):\s*(.*)/,
    );
    if (!topLevel) {
      index++;
      continue;
    }

    const key = topLevel[1];
    const value = topLevel[2].trim();
    if (value === ">-" || value === ">") {
      const parts = [];
      index++;
      while (
        index < lines.length &&
        (lines[index].startsWith("  ") || lines[index].trim() === "")
      ) {
        if (lines[index].trim()) parts.push(lines[index].trim());
        index++;
      }
      result[key] = parts.join(" ");
      continue;
    }

    if (value === "") {
      index++;
      if (index < lines.length && /^  - /.test(lines[index])) {
        const items = [];
        while (index < lines.length && /^  - /.test(lines[index])) {
          items.push(parseScalar(lines[index].replace(/^  - /, "")));
          index++;
        }
        result[key] = items;
      } else {
        const objectValue = {};
        while (index < lines.length) {
          const nested = lines[index].match(
            /^  ([a-zA-Z][a-zA-Z0-9-]*):\s*(.*)/,
          );
          if (!nested) break;
          objectValue[nested[1]] = parseScalar(nested[2]);
          index++;
        }
        if (Object.keys(objectValue).length > 0) result[key] = objectValue;
      }
      continue;
    }

    result[key] = parseScalar(value);
    index++;
  }

  return result;
}

function parseSkill(reference) {
  const name = reference
    .replace("./skills/", "")
    .replace(/\/$/, "");
  const skillDir = join(root, "skills", name);
  const content = readFileSync(join(skillDir, "SKILL.md"), "utf8");
  const frontmatter = parseFrontmatterFields(content);
  const listFiles = (folder) => {
    const path = join(skillDir, folder);
    return existsSync(path)
      ? readdirSync(path).filter((item) => !item.startsWith(".")).sort()
      : [];
  };

  return {
    name,
    description: frontmatter.description ?? "",
    metadata: frontmatter.metadata ?? null,
    compatibility: frontmatter.compatibility ?? null,
    argumentHint: frontmatter["argument-hint"] ?? null,
    userInvocable: frontmatter["user-invocable"] ?? null,
    scripts: listFiles("scripts"),
    assets: [...listFiles("references"), ...listFiles("assets")],
    githubUrl: `${githubBase}/tree/main/skills/${name}`,
  };
}

function parseAgent(reference) {
  const name = reference
    .replace("./agents/", "")
    .replace(/\.md$/, "");
  const path = join(root, "agents", `${name}.agent.md`);
  const frontmatter = parseFrontmatterFields(readFileSync(path, "utf8"));

  return {
    name,
    description: frontmatter.description ?? "",
    tools: frontmatter.tools ?? null,
    subAgents: frontmatter.agents ?? null,
    userInvocable: frontmatter["user-invocable"] ?? null,
    githubUrl: `${githubBase}/blob/main/agents/${name}.agent.md`,
  };
}

function extractCanvasMetadata(extensionSource) {
  const start = extensionSource.indexOf("createCanvas({");
  if (start === -1) return {};
  const registration = extensionSource.slice(start, start + 1200);
  const readField = (field) =>
    registration.match(
      new RegExp(`^\\s*${field}:\\s*["']([^"']+)["']`, "m"),
    )?.[1];

  return {
    canvasId: readField("id"),
    displayName: readField("displayName"),
    canvasDescription: readField("description"),
  };
}

function parseExtension(reference, plugin) {
  const id = reference.replace("./extensions/", "").replace(/\/$/, "");
  const extensionDir = join(root, "extensions", id);
  const source = readFileSync(join(extensionDir, "extension.mjs"), "utf8");
  const packageJson = readJson(join(extensionDir, "package.json"));
  const readme = readFileSync(join(extensionDir, "README.md"), "utf8");
  const canvas = extractCanvasMetadata(source);
  const previewName = `${id}.png`;
  cpSync(
    join(extensionDir, "assets", "preview.png"),
    join(previewDir, previewName),
    { force: true },
  );

  return {
    id,
    canvasId: canvas.canvasId ?? id,
    name: canvas.displayName ?? plugin.name,
    description: canvas.canvasDescription ?? plugin.description,
    version: plugin.version,
    author: plugin.author ?? null,
    keywords: plugin.keywords ?? [],
    platform: "Windows",
    previewUrl: `extension-previews/${previewName}`,
    readmeHtml: marked.parse(readme),
    sourceUrl: `${githubBase}/tree/main/extensions/${id}`,
    pluginName: plugin.name,
    installCommand: `copilot plugin install ${plugin.name}@plagueho-copilot`,
  };
}

const marketplace = readJson(
  join(root, ".github", "plugin", "marketplace.json"),
);
const extensionsById = new Map();

const plugins = marketplace.plugins.map((marketplacePlugin) => {
  const pluginDir = join(root, "plugins", marketplacePlugin.source);
  const plugin = readJson(join(pluginDir, "plugin.json"));
  const composition = plugin.extensions?.[compositionNamespace] ?? {};
  const canvasExtensions = (composition.extensions ?? []).map((reference) => {
    const extension = parseExtension(reference, plugin);
    extensionsById.set(extension.id, extension);
    return extension;
  });
  const readmePath = join(pluginDir, "README.md");

  return {
    name: plugin.name,
    description: plugin.description,
    version: plugin.version,
    keywords: plugin.keywords ?? [],
    skills: (composition.skills ?? []).map(parseSkill),
    agents: (composition.agents ?? []).map(parseAgent),
    extensions: canvasExtensions.map(({ id, name, description }) => ({
      id,
      name,
      description,
    })),
    readmeHtml: existsSync(readmePath)
      ? marked.parse(readFileSync(readmePath, "utf8"))
      : "",
  };
});

const data = {
  name: marketplace.name,
  description: marketplace.metadata.description,
  version: marketplace.metadata.version,
  owner: marketplace.owner,
  plugins,
  extensions: [...extensionsById.values()].sort((left, right) =>
    left.name.localeCompare(right.name),
  ),
};

writeFileSync(
  join(dataDir, "data.json"),
  `${JSON.stringify(data, null, 2)}\n`,
  "utf8",
);

const totalSkills = plugins.reduce(
  (sum, plugin) => sum + plugin.skills.length,
  0,
);
const totalAgents = plugins.reduce(
  (sum, plugin) => sum + plugin.agents.length,
  0,
);
console.log(
  `Generated catalog data: ${plugins.length} plugins, ${totalSkills} skills, ${totalAgents} agents, ${data.extensions.length} extensions.`,
);
