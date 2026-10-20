# Azure Infrastructure Deployment Plugin

Infrastructure management plugin that provisions Azure identities for GitHub and keeps Azure Verified Module references up to date.

## Installation

```bash
# Using Copilot CLI
copilot plugin install azure-infrastructure-deployment@plagueho-copilot
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

## AVM runtime and safety

The AVM skill requires Node.js 22+ and network access to MCR and GitHub.
Build validation also requires Azure CLI with Bicep installed; version checks do not.
PowerShell 7+ and Bash wrappers share one `.mjs` implementation; curl and jq are not required.
Updates require a discovery hash and a new rollback snapshot.
Version and approved parameter edits are restored together if validation fails.
Snapshots contain source code; keep them in a private session directory outside the repository.
Build validation does not deploy resources or prove deployment compatibility.

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
