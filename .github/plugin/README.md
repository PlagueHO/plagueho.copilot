# Copilot Plugin Marketplace

This directory contains the generated marketplace index and schemas for `PlagueHO/plagueho.copilot`.

## Add the Marketplace

```json
{
  "chat.plugins.enabled": true,
  "chat.plugins.marketplaces": [
    "PlagueHO/plagueho.copilot"
  ]
}
```

For GitHub Copilot CLI:

```text
/plugin marketplace add PlagueHO/plagueho.copilot
```

## Source Model

- `plugins/<plugin>/plugin.json` contains Agent Plugins 1.0.0 metadata.
- `skills/`, `agents/`, and `extensions/` contain reusable source resources.
- `extensions["com.github.plagueho"]` declares build-time composition.
- `eng/materialize-plugins.mjs` creates conventional installable plugin folders.
- The `marketplace` branch is generated distribution output and must not be edited directly.

Regenerate both marketplace indexes with either wrapper:

```powershell
./scripts/Update-MarketplaceFromPlugins.ps1
```

```bash
./scripts/update-marketplace-from-plugins.sh
```

Validate source manifests and references:

```bash
pnpm plugin:validate
npx --yes ajv-cli validate \
  -s .github/plugin/marketplace.schema.json \
  -d .github/plugin/marketplace.json
npx --yes ajv-cli validate \
  -s .github/plugin/plugin.schema.json \
  -d "plugins/*/plugin.json"
```
