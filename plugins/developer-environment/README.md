# Developer Environment Plugin

Developer environment plugin that scaffolds dotfiles repositories and synchronizes VS Code profiles across editions.

## Installation

```bash
# Using Copilot CLI
copilot plugin install developer-environment@plagueho-os
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/developer-environment:create-dotfiles-repo` | Scaffold a dotfiles template repository in a GitHub Organization from an existing workspace. Scans for shell, git, editor, and package configs and generates bootstrap installers. |
| `/developer-environment:vscode-profile-sync` | Replicate VS Code Insiders profiles and extensions into VS Code stable. Discovers profiles, diffs extensions, installs missing ones, and optionally removes extras. |

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
