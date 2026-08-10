---
name: provision-github-azure-federated-identity

description: "**WORKFLOW SKILL** — Provision Azure User Assigned Managed Identity with OIDC federation and RBAC for passwordless GitHub authentication. WHEN: \"set up Azure access for GitHub Actions\", \"configure managed identity for GitHub\", \"enable passwordless Azure authentication in CI/CD\", \"configure OIDC federation GitHub Azure\", \"Copilot coding agent Azure identity\". INVOKES: run_in_terminal for PowerShell. FOR SINGLE OPERATIONS: Use az CLI for simple role assignments."

metadata:
  author: PlagueHO
  version: "2.0"
  reference: https://github.com/PlagueHO/plagueho.os/

compatibility: Requires PowerShell 7+, Az.Accounts ≥ 5.3.2, Az.Resources ≥ 9.0.0, Az.ManagedServiceIdentity ≥ 2.0.0, and an authenticated Azure session (Connect-AzAccount) with permission to create resource groups and assign RBAC roles at subscription scope.

argument-hint: Provide the target GitHub repository name and identity type ('actions' or 'codingAgent'). For 'actions' type also provide the environment name. Optionally provide GitHub organization, Azure subscription ID, Azure location, and RBAC role overrides.

user-invocable: true
---

## Overview

This skill provisions **one** Azure User Assigned Managed Identity (UAMI) per invocation for
GitHub OIDC authentication — no long-lived credentials required. To cover multiple environments
or both GitHub Actions and Copilot coding agent, run the script once per identity needed.

Each invocation creates or verifies (idempotent):

- A shared **resource group** (`rg-github-<RepositoryName>-mi`) for GitHub integration resources
- One **User Assigned Managed Identity** for either a GitHub Actions deployment environment or
  the GitHub Copilot coding agent
- A **Federated Identity Credential** on the identity, binding it to the specified GitHub context
  via OIDC
- **RBAC role assignments** at subscription scope:
  - `Contributor` — allows creating and managing Azure resources
  - `User Access Administrator` (with conditions) — allows role assignment but prevents granting
    `Owner`, `User Access Administrator`, or `Role Based Access Control Administrator` to any
    principal

If a resource already exists, the script skips creation and outputs the existing details.

## Prerequisites

1. **Azure PowerShell modules** installed (the script validates this):
   - `Az.Accounts` ≥ 5.3.2
   - `Az.Resources` ≥ 9.0.0
   - `Az.ManagedServiceIdentity` ≥ 2.0.0

   Install missing modules with:

   ```powershell
   Install-Module -Name Az.Accounts, Az.Resources, Az.ManagedServiceIdentity -Scope CurrentUser -Force
   ```

2. **Authenticated Azure session** — run `Connect-AzAccount` if not already authenticated.

3. The authenticated identity must have **subscription-level permissions** to:
   - Create resource groups
   - Create managed identities (`Microsoft.ManagedIdentity/userAssignedIdentities/write`)
   - Assign RBAC roles (`Microsoft.Authorization/roleAssignments/write`)

## Script

The PowerShell script is bundled inside this skill's `scripts/` subdirectory — it is **not** in
the active workspace. Before running, resolve the absolute path as follows:

1. Note the absolute path of this SKILL.md file (available from the `filePath` attribute of
   the skill attachment in context)
2. Replace `SKILL.md` with `scripts/Update-AzureUserAssignedManagedIdentityForGitHub.ps1` to
   get the full script path
3. Confirm the file exists by calling `list_dir` on the skill's `scripts/` subfolder

Always use the full absolute path when invoking the script via `#runInTerminal`.

> [!IMPORTANT]
> Don't search for the script in any other location. Do not create the script if you can't find it — 🛑 and report the issue instead.

## Script parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `RepositoryName` | Yes | — | GitHub repository name (not the full `org/repo` path) |
| `Type` | No | `actions` | Identity purpose: `actions` (GitHub Actions environment) or `codingAgent` (Copilot coding agent) |
| `Environment` | No | `test` | GitHub environment name — **only used when `Type` is `actions`** |
| `GitHubOrganization` | No | `PlagueHO` | GitHub organization or user account owning the repository |
| `SubscriptionId` | No | Current context | Azure subscription ID to deploy resources into |
| `Location` | No | `New Zealand North` | Azure region for the resource group and identity |
| `ResourceGroupName` | No | `rg-github-<RepositoryName>-mi` | Override the resource group name |
| `IdentityName` | No | Computed (see naming) | Override the UAMI name |
| `RbacRoles` | No | `@('Contributor','User Access Administrator')` | RBAC role names to assign at subscription scope — overrides the default set |
| `RemoveUnlistedRoles` | No | `$false` | Remove any subscription-scope role assignments for this identity that are absent from `-RbacRoles` |
| `Force` | No | `$false` | Skip interactive confirmation prompts |

## Resource naming

| Resource | Default name |
|----------|-------------|
| Resource group | `rg-github-<RepositoryName>-mi` |
| UAMI — `actions` type | `mi-actions-<RepositoryName>-<Environment>-env` |
| UAMI — `codingAgent` type | `mi-coding-agent-<RepositoryName>` |
| Federated credential — `actions` | `<GitHubOrganization>-<RepositoryName>-<Environment>` |
| Federated credential — `codingAgent` | `<GitHubOrganization>-<RepositoryName>-copilot` |

Use `-ResourceGroupName` or `-IdentityName` to override the computed defaults when needed.

## How to use this skill

### Step 1 — Gather required information

Ask the user for (or infer from context):

- **`RepositoryName`** (required) — GitHub repo name
- **`Type`** — `actions` for a deployment environment, `codingAgent` for Copilot coding agent
- **`Environment`** — GitHub environment name (required when `Type` is `actions`; e.g. `test`, `staging`, `prod`)
- **`GitHubOrganization`** — if not the default `PlagueHO`
- **`SubscriptionId`** — if targeting a specific Azure subscription

For multiple environments or both GitHub Actions and Copilot agent access, plan to run the
script once per identity required.

### Step 2 — Run the script

Use `#runInTerminal` to execute from a PowerShell session already authenticated to Azure.

**GitHub Actions identity for a single environment:**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'actions' `
    -Environment 'test'
```

**GitHub Actions identities for multiple environments (run once per environment):**

```powershell
foreach ($env in @('test', 'staging', 'prod')) {
    .\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
        -RepositoryName 'my-repo' `
        -Type 'actions' `
        -Environment $env `
        -Force
}
```

**Copilot coding agent identity:**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'codingAgent'
```

**Full invocation with all common parameters:**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'actions' `
    -Environment 'prod' `
    -GitHubOrganization 'MyOrg' `
    -SubscriptionId '12345678-1234-1234-1234-123456789012' `
    -Location 'East US' `
    -Force
```

**Custom RBAC roles (overrides defaults):**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'actions' `
    -Environment 'prod' `
    -RbacRoles @('Contributor')
```

**Remove roles no longer required:**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'actions' `
    -Environment 'prod' `
    -RbacRoles @('Contributor') `
    -RemoveUnlistedRoles
```

**Preview changes without applying (`-WhatIf`):**

```powershell
.\scripts\Update-AzureUserAssignedManagedIdentityForGitHub.ps1 `
    -RepositoryName 'my-repo' `
    -Type 'actions' `
    -Environment 'test' `
    -WhatIf
```

### Step 3 — Configure GitHub repository secrets and environments

After each script run, it outputs the values needed for GitHub.

**Repository-level secrets** (`Settings → Secrets and variables → Actions`):

| Secret | Value |
|--------|-------|
| `AZURE_TENANT_ID` | Azure AD tenant ID (printed by script) |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID (printed by script) |

**Per-environment secret** (`Settings → Environments → <env name> → Secrets`):

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `clientId` of the managed identity for that environment (printed by script) |

For the Copilot coding agent, create a GitHub environment named `copilot` and set
`AZURE_CLIENT_ID` under it.

### Step 4 — Use the managed identity in GitHub Actions

```yaml
permissions:
  id-token: write   # Required for OIDC token request
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: test   # Must match the environment name used when creating the identity
    steps:
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

For Copilot coding agent workflows, use `environment: copilot`.

## Idempotency

Running the script multiple times against the same repository is **safe**. Each resource
(resource group, UAMI, federated credential, role assignment) is checked before creation.
If it already exists, it is skipped and its current details are included in the output.
Re-running is the standard approach to update a subset of environments or verify state.

## RBAC role management

- Default roles: `Contributor` and `User Access Administrator`.
- Pass `-RbacRoles` to specify a different set of roles — this **replaces** the defaults entirely
  for that invocation.
- By default, roles already assigned to the identity but **absent from `-RbacRoles`** are
  **left intact**.
- Pass `-RemoveUnlistedRoles` to also **remove** any subscription-scope role assignments for the
  identity that are not listed in `-RbacRoles`.
- `User Access Administrator` is **always** assigned with a condition preventing the identity from
  granting `Owner`, `User Access Administrator`, or `Role Based Access Control Administrator` to
  any principal, regardless of whether the role list was customised.

## Edge cases and when to pause

- **`RepositoryName` not provided** — only mandatory parameter; ask before running.
- **`Type` not specified** — ask whether the identity is for GitHub Actions (`actions`) or Copilot
  coding agent (`codingAgent`).
- **`Environment` not specified for `actions` type** — ask for the environment name; each
  environment requires a separate script execution.
- **Multiple environments** — confirm the list before running; one execution is needed per
  environment.
- **Non-default `SubscriptionId`** — confirm which subscription to use if it differs from the
  current Azure context.
- **`-Force` flag** — do not pass unless the user explicitly requests skipping prompts; without
  it the script confirms each resource creation interactively.
- **`-RemoveUnlistedRoles`** — confirm with the user before using; roles assigned outside this
  script could be intentional.
- **Role assignment failures** — the script retries up to 3 times. If all retries fail, surface
  the error and ask the user to verify Azure permissions before retrying.

## Security notes

- No static credentials are created. All authentication uses short-lived OIDC tokens issued by
  GitHub at runtime.
- `User Access Administrator` is granted with a condition expression that prevents assignment of
  `Owner`, `User Access Administrator`, or `Role Based Access Control Administrator`, following
  the principle of least privilege.
- Script output includes tenant and subscription IDs. These are non-secret identifiers but should
  not be committed to public repositories — store them as GitHub secrets.
