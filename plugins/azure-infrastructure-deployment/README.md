# Azure Infrastructure Deployment Plugin

Infrastructure management plugin that provisions Azure identities for GitHub and keeps Azure Verified Module references up to date.

## Installation

```bash
# Using Copilot CLI
copilot plugin install azure-infrastructure-deployment@plagueho-os
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/azure-infrastructure:azure-github-managed-identity` | Provision Azure User Assigned Managed Identities with OIDC federation and RBAC for passwordless GitHub authentication. |
| `/azure-infrastructure:update-avm-modules` | Update Azure Verified Modules (AVM) to their latest versions in Bicep files. Scans for AVM module references, queries MCR for latest versions, and applies updates with validation. |

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
