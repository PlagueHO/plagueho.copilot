import {
  cpSync,
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  writeFileSync,
} from "node:fs";
import { basename, dirname, join } from "node:path";

export const AGENT_PLUGIN_SCHEMA_URL =
  "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json";
export const COMPOSITION_NAMESPACE = "com.github.plagueho";
export const COPILOT_NAMESPACE = "com.github.copilot";
export const REPOSITORY_URL =
  "https://github.com/PlagueHO/plagueho.copilot";

const RESOURCE_SPECS = {
  agents: {
    prefix: "./agents/",
    suffix: ".md",
    sourcePath(root, name) {
      return join(root, "agents", `${name}.agent.md`);
    },
    destinationPath(pluginDir, name) {
      return join(pluginDir, "agents", `${name}.md`);
    },
  },
  extensions: {
    prefix: "./extensions/",
    suffix: "",
    sourcePath(root, name) {
      return join(root, "extensions", name);
    },
    destinationPath(pluginDir, name) {
      return join(pluginDir, "extensions", name);
    },
  },
  skills: {
    prefix: "./skills/",
    suffix: "/",
    sourcePath(root, name) {
      return join(root, "skills", name);
    },
    destinationPath(pluginDir, name) {
      return join(pluginDir, "skills", name);
    },
  },
};

export function readJson(filePath) {
  return JSON.parse(readFileSync(filePath, "utf8"));
}

export function writeJson(filePath, value) {
  writeFileSync(filePath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
}

export function readPluginEntries(root) {
  const pluginsDir = join(root, "plugins");
  if (!existsSync(pluginsDir)) {
    return [];
  }

  return readdirSync(pluginsDir, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => {
      const pluginDir = join(pluginsDir, entry.name);
      const manifestPath = join(pluginDir, "plugin.json");
      if (!existsSync(manifestPath)) {
        return null;
      }

      return {
        directoryName: entry.name,
        manifest: readJson(manifestPath),
        manifestPath,
        pluginDir,
      };
    })
    .filter(Boolean)
    .sort((left, right) =>
      left.directoryName.localeCompare(right.directoryName),
    );
}

export function getComposition(manifest) {
  return manifest.extensions?.[COMPOSITION_NAMESPACE] ?? {};
}

export function parseResourceReference(kind, reference) {
  const spec = RESOURCE_SPECS[kind];
  if (!spec || typeof reference !== "string") {
    return null;
  }
  if (!reference.startsWith(spec.prefix) || !reference.endsWith(spec.suffix)) {
    return null;
  }

  const end = spec.suffix ? -spec.suffix.length : undefined;
  const name = reference.slice(spec.prefix.length, end);
  if (!/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$/.test(name)) {
    return null;
  }

  return { kind, name, reference, spec };
}

export function resolveResource(root, pluginDir, kind, reference) {
  const parsed = parseResourceReference(kind, reference);
  if (!parsed) {
    return null;
  }

  return {
    ...parsed,
    sourcePath: parsed.spec.sourcePath(root, parsed.name),
    destinationPath: parsed.spec.destinationPath(pluginDir, parsed.name),
  };
}

export function createServedManifest(manifest) {
  const served = { ...manifest };
  const extensions = { ...(manifest.extensions ?? {}) };
  delete extensions[COMPOSITION_NAMESPACE];

  if (Object.keys(extensions).length > 0) {
    served.extensions = extensions;
  } else {
    delete served.extensions;
  }

  return served;
}

export function materializePlugin(root, entry) {
  const composition = getComposition(entry.manifest);
  const copied = [];

  for (const kind of Object.keys(RESOURCE_SPECS)) {
    for (const reference of composition[kind] ?? []) {
      const resource = resolveResource(
        root,
        entry.pluginDir,
        kind,
        reference,
      );
      if (!resource || !existsSync(resource.sourcePath)) {
        throw new Error(
          `${entry.directoryName}: source not found for ${kind} reference ${reference}`,
        );
      }

      mkdirSync(dirname(resource.destinationPath), { recursive: true });
      cpSync(resource.sourcePath, resource.destinationPath, {
        recursive: true,
        force: true,
      });
      copied.push(resource);
    }
  }

  const logo = entry.manifest.extensions?.[COPILOT_NAMESPACE]?.logo;
  if (logo) {
    const extension = copied.find(
      (resource) =>
        resource.kind === "extensions" &&
        resource.name === entry.directoryName,
    );
    if (!extension) {
      throw new Error(
        `${entry.directoryName}: Copilot logo requires a matching extension source`,
      );
    }

    const sourceLogo = join(extension.sourcePath, logo);
    const destinationLogo = join(entry.pluginDir, logo);
    if (!existsSync(sourceLogo)) {
      throw new Error(
        `${entry.directoryName}: extension logo not found at ${sourceLogo}`,
      );
    }
    mkdirSync(dirname(destinationLogo), { recursive: true });
    cpSync(sourceLogo, destinationLogo, { force: true });
  }

  writeJson(entry.manifestPath, createServedManifest(entry.manifest));
  return copied;
}

export function listTopLevelResourceNames(root, kind) {
  const folder = join(root, kind);
  if (!existsSync(folder)) {
    return [];
  }

  const entries = readdirSync(folder, { withFileTypes: true });
  if (kind === "agents") {
    return entries
      .filter((entry) => entry.isFile() && entry.name.endsWith(".agent.md"))
      .map((entry) => basename(entry.name, ".agent.md"))
      .sort();
  }

  return entries
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
}
