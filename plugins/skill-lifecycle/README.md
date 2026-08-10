# Skill Lifecycle Plugin

Skill authoring plugin that creates, converts, and generates GitHub Copilot Agent Skills from various sources.

## Installation

```bash
# Using Copilot CLI
copilot plugin install skill-lifecycle@plagueho-os
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/skill-lifecycle:skill-creator` | Create a new Agent Skill from a description and goal, following the agentskills.io specification. Scaffolds directory structure, generates SKILL.md with YAML frontmatter, and validates the result. |
| `/skill-lifecycle:convert-prompt-to-skill` | Convert an existing GitHub Copilot prompt file (.prompt.md) into a conformant Agent Skill (SKILL.md) following the agentskills.io specification. |
| `/skill-lifecycle:create-skill-from-pr` | Generate a reusable GitHub Copilot Agent Skill from a single-purpose refactoring or tech debt Pull Request. |

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
