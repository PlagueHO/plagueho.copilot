# Repository Instructions

Copilot resource catalog for Daniel Scott-Raynsford (PlagueHO). Contains
reusable skills, agents, canvas extensions, and plugin manifests published via
`github.com/PlagueHO/plagueho.copilot`.
For code style, naming, and authoring patterns see
`.github/copilot-instructions.md`.

## Layout

```text
skills/<skill-name>/         # Canonical reusable skills
  SKILL.md
  scripts/
  references/
  assets/
agents/<agent>.agent.md      # Canonical reusable agents
extensions/<extension>/      # Canonical canvas extension sources
  extension.mjs
  package.json
  README.md
  assets/preview.png
plugins/<plugin>/            # Lightweight composition manifests
  plugin.json
  README.md
tests/<skill-name>/
  trigger_tests.yaml         # Skill activation test cases
scripts/
  Update-MarketplaceFromPlugins.ps1
  update-marketplace-from-plugins.sh
.github/
  plugin/
    marketplace.json         # Generated marketplace index
    marketplace.schema.json
    plugin.schema.json
  workflows/
    continuous-integration.yml
  copilot-instructions.md
.claude-plugin/
  marketplace.json           # Must be exact mirror of .github/plugin/marketplace.json
docs/images/overview.svg     # Plugin catalog SVG (skill counts + names)
eng/                         # Validation and materialization tooling
```

## Commands

Always run before submitting changes:

```bash
pnpm install          # Install dependencies (required before lint)
pnpm plugin:validate  # Validate manifests and reusable references
pnpm test             # Test publishing tooling
pnpm lint:md          # Lint all Markdown files (must pass)
```

Single-file lint (faster agent loop):

```bash
npx markdownlint-cli2 path/to/file.md
```

Validate JSON schemas:

```bash
npx --yes ajv-cli validate -s .github/plugin/marketplace.schema.json -d .github/plugin/marketplace.json
npx --yes ajv-cli validate -s .github/plugin/plugin.schema.json -d plugins/<plugin>/plugin.json
```

Verify marketplace sync (must produce no output):

```bash
diff .github/plugin/marketplace.json .claude-plugin/marketplace.json
```

## Adding a New Skill — Atomic Checklist

All of the following must be updated in the **same commit**:

1. `skills/<skill-name>/SKILL.md` — create the reusable skill
2. `plugins/<plugin>/plugin.json` — add `"./skills/<skill-name>/"` to `extensions["com.github.plagueho"].skills`
3. `.github/plugin/marketplace.json` — bump plugin `version` (patch or minor)
4. `.claude-plugin/marketplace.json` — mirror step 3 exactly (must be identical)
5. `README.md` — update plugin row if skill count or description changes
6. `docs/images/overview.svg` — update resource counts and plugin list
7. `tests/<skill-name>/trigger_tests.yaml` — add activation test cases

Omitting any of these leaves the marketplace index, README, and overview out
of sync and will fail CI.

After editing `plugin.json` files, optionally regenerate the marketplace index:

```powershell
# PowerShell
& scripts/Update-MarketplaceFromPlugins.ps1
```

```bash
# Shell
./scripts/update-marketplace-from-plugins.sh
```

## CI Pipeline

The `continuous-integration.yml` workflow validates on every push/PR to `main`:

- **Secret scan**: TruffleHog (`--only-verified`) — no credentials anywhere
- **YAML syntax**: all `.yml`/`.yaml` files parsed with Python
- **JSON syntax**: all `.json` files parsed with Python
- **Markdown lint**: `pnpm lint:md` (rules in `.markdownlint.json`)
- **marketplace.json schema**: validated against `marketplace.schema.json`
- **plugin.json schemas**: every `plugins/*/plugin.json` validated against `plugin.schema.json`
- **Marketplace sync**: `diff .github/plugin/marketplace.json .claude-plugin/marketplace.json` must produce no output

All checks must pass before merging.

## Conventions

| Concern | Rule |
|---------|------|
| Naming | kebab-case for plugin names, skill names, script filenames |
| YAML/JSON indentation | 2 spaces |
| PowerShell/Python indentation | 4 spaces |
| Line endings | LF; newline at end of every file; no trailing whitespace |
| Scripts | Always provide both `.ps1` (PowerShell 7+) and `.sh` (Bash) variants |
| `plugin.json` repository field | Always `"https://github.com/PlagueHO/plagueho.copilot"` |
| SKILL.md body length | Keep under 500 lines; move detail to `references/` files |
| Script headers | Include comment block: purpose, parameters, usage |

## Dos and Don'ts

- **Do** run `pnpm lint:md` before every commit
- **Do** update all 7 checklist items in a single commit when adding a skill
- **Don't** edit `marketplace.json` by hand — use the regeneration scripts
- **Don't** push to `main` without passing all CI checks
- Edit files freely; ask before `git push`, deleting files, or adding dependencies
- When stuck, propose a plan — do not push large speculative changes

## Reference Examples

- **Well-structured skill**: `skills/update-avm-modules/SKILL.md`
- **Trigger tests**: `tests/update-avm-modules/trigger_tests.yaml`
