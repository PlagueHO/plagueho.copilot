# Contributing

Thanks for contributing to the PlagueHO Copilot Catalog.

## Repository Layout

```text
agents/<agent>.agent.md
extensions/<extension>/
  extension.mjs
  package.json
  README.md
  assets/preview.png
skills/<skill>/
  SKILL.md
  scripts/
  references/
  assets/
plugins/<plugin>/
  plugin.json
  README.md
tests/<skill>/trigger_tests.yaml
```

Reusable resources live once at the repository root. Plugins compose them through `extensions["com.github.plagueho"]`; do not copy reusable source into plugin directories on `main`.

## Add a Skill

1. Create `skills/<skill-name>/SKILL.md` with valid frontmatter.
2. Add `"./skills/<skill-name>/"` to a plugin's sorted `extensions["com.github.plagueho"].skills` array.
3. Add `tests/<skill-name>/trigger_tests.yaml`.
4. Bump the plugin version.
5. Regenerate the marketplace indexes with `pnpm marketplace:generate`.
6. Update the root catalog and overview when counts or descriptions change.

Keep `SKILL.md` under 500 lines, use kebab-case names, and keep bundled scripts, references, and assets within the skill directory.

## Add an Agent

1. Create `agents/<agent-name>.agent.md`.
2. Add `"./agents/<agent-name>.md"` to a plugin's sorted `extensions["com.github.plagueho"].agents` array.
3. Bump the plugin version and regenerate the marketplace indexes.

The `.agent.md` source suffix is materialized as `.md` in the installable plugin.

## Add a Canvas Extension

1. Create `extensions/<extension-name>/` with `extension.mjs`, `package.json`, `README.md`, and `assets/preview.png`.
2. Exclude user-specific configuration and runtime state such as `copilot-extension.json` and `artifacts/`.
3. Create a matching standalone `plugins/<extension-name>/plugin.json` and `README.md`.
4. Reference `"./extensions/<extension-name>"` in the plugin composition metadata.
5. Set `extensions["com.github.copilot"].logo` to `assets/preview.png`.
6. Add focused extension tests and update the website catalog.

Canvas extensions published here target the GitHub Copilot app. Do not advertise unsupported canvas hosts.

## Validate Changes

```bash
pnpm install
pnpm plugin:validate
pnpm test
pnpm marketplace:generate
pnpm lint:md
npx --yes ajv-cli validate -s .github/plugin/marketplace.schema.json -d .github/plugin/marketplace.json
npx --yes ajv-cli validate \
  -s .github/plugin/plugin.schema.json \
  -d "plugins/*/plugin.json"
```

Build the website when catalog data or presentation changes:

```bash
npm --prefix website install
node website/build.mjs
npm --prefix website run build
```

## Security and Licensing

- Never include secrets, tokens, private URLs, or user data.
- Validate external inputs and apply least privilege.
- Submit only content you have the right to contribute.
