## Description

Brief description of the changes in this PR.

## Plugin / Skill Affected

- **Plugin:** `<plugin-name>`
- **Skill:** `<skill-name>` (if applicable)

## Type of Change

- [ ] New skill
- [ ] Skill update / improvement
- [ ] New plugin
- [ ] Bug fix
- [ ] Documentation update
- [ ] Infrastructure / CI change

## Checklist

- [ ] SKILL.md has valid YAML frontmatter (`name`, `description`)
- [ ] SKILL.md body is under 500 lines
- [ ] `plugin.json` is updated (if applicable)
- [ ] `marketplace.json` is regenerated (run `scripts/Update-MarketplaceFromPlugins.ps1`)
- [ ] `.claude-plugin/marketplace.json` matches `.github/plugin/marketplace.json`
- [ ] Tests added / updated under `tests/`
- [ ] No secrets or credentials included
