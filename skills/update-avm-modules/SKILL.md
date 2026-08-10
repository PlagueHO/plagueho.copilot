---
name: update-avm-modules

description: >-
  **WORKFLOW SKILL** — Update Azure Verified Modules (AVM) to their latest
  versions in Bicep files. Scans for AVM module references, queries the
  Microsoft Container Registry (MCR) for latest versions, compares using
  semantic versioning, reviews breaking changes, and applies updates with
  validation. WHEN: 'update AVM', 'update Bicep modules', 'latest AVM versions',
  'update Azure Verified Modules', 'upgrade Bicep dependencies', 'check AVM
  versions', 'update module versions'. INVOKES: run_in_terminal for MCR API
  queries and bicep lint. FOR SINGLE OPERATIONS: Use az bicep build to validate
  individual files.

metadata:
  author: plagueho.os
  version: "1.0"
  reference: https://github.com/Azure/bicep-registry-modules

compatibility:
  - GitHub Copilot
  - VS Code
  - Requires az CLI with Bicep extension
  - Requires network access to mcr.microsoft.com

argument-hint: >-
  Specify the Bicep file(s) to update (e.g., "infra/main.bicep") or say
  "all Bicep files" to scan the entire infra/ directory.

user-invocable: true
---

# Update AVM Modules

## Prerequisites

- **Azure CLI** with Bicep extension (`az bicep build` must work).
- **Network access** to `mcr.microsoft.com` for version queries.
- **PowerShell 7+** (Windows) or **curl + jq** (macOS/Linux).

## Script Dependency Policy

All automation steps **MUST** use the bundled scripts in `scripts/`. If any
required script cannot be found at runtime:

1. **STOP the workflow immediately.**
2. Report the missing script path to the user.
3. Do NOT fall back to calling APIs directly, manual extraction, or hand
   editing.

Required scripts:

| Script (PowerShell) | Script (Shell) | Purpose |
|---------------------|---------------|---------|
| `Get-AvmModuleReferences.ps1` | `get-avm-module-references.sh` | Extract AVM references |
| `Get-AvmLatestVersions.ps1` | `get-avm-latest-versions.sh` | Query MCR for latest versions |
| `Update-AvmVersions.ps1` | `update-avm-versions.sh` | Apply version updates |
| `Test-BicepBuild.ps1` | `test-bicep-build.sh` | Validate Bicep files |

## Resolving the Scripts Directory

Derive the scripts path from this SKILL.md file path (provided as the
attachment source path). The `scripts/` subdirectory is a sibling of this
file:

```text
<skill-root>/SKILL.md
<skill-root>/scripts/Get-AvmLatestVersions.ps1
```

All steps below reference `$skillPath` (PowerShell) or `$SKILL_PATH` (Shell)
resolved as:

- PowerShell: `$skillPath = Split-Path -Parent "<absolute-path-to-this-SKILL.md>"`
- Shell: `SKILL_PATH="$(dirname "<absolute-path-to-this-SKILL.md>")"`

## Process

### Step 1 — Identify Target Files

Determine which Bicep files to update:

- If the user specified a file, use that file.
- If the user said "all", scan `infra/` recursively for `*.bicep` files.
- List the files and confirm with the user before proceeding.

### Step 2 — Extract Module References

Run `Get-AvmModuleReferences.ps1` / `get-avm-module-references.sh`.

**PowerShell** (Windows):

```powershell
$skillPath = Split-Path -Parent "<absolute-path-to-this-SKILL.md>"
$script = Join-Path $skillPath "scripts/Get-AvmModuleReferences.ps1"
if (-not (Test-Path $script)) {
    Write-Error "FATAL: Script not found: $script — aborting workflow."
    exit 1
}
# Single file
& $script -BicepFile "<path>"
# Or entire directory
& $script -Directory "infra/"
```

**Shell** (macOS/Linux):

```bash
SKILL_PATH="$(dirname "<absolute-path-to-this-SKILL.md>")"
SCRIPT="$SKILL_PATH/scripts/get-avm-module-references.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "FATAL: Script not found: $SCRIPT — aborting workflow." >&2
    exit 1
fi
# Single file
"$SCRIPT" --file "<path>"
# Or entire directory
"$SCRIPT" --directory "infra/"
```

Outputs JSON with `Module`, `Version`, `FilePath`, `LineNumber` per reference.
If no AVM modules are found, inform the user and stop.

### Step 3 — Query Latest Versions

Run `Get-AvmLatestVersions.ps1` / `get-avm-latest-versions.sh`.

**PowerShell** (Windows):

```powershell
$skillPath = Split-Path -Parent "<absolute-path-to-this-SKILL.md>"
$script = Join-Path $skillPath "scripts/Get-AvmLatestVersions.ps1"
if (-not (Test-Path $script)) {
    Write-Error "FATAL: Script not found: $script — aborting workflow."
    exit 1
}
& $script -BicepFile "<path>"
```

**Shell** (macOS/Linux):

```bash
SKILL_PATH="$(dirname "<absolute-path-to-this-SKILL.md>")"
SCRIPT="$SKILL_PATH/scripts/get-avm-latest-versions.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "FATAL: Script not found: $SCRIPT — aborting workflow." >&2
    exit 1
fi
"$SCRIPT" "<path>"
```

Outputs a human-readable table (`Module`, `Current`, `Latest`, `Status`) and
a JSON array for machine consumption.

### Step 4 — Compare and Classify

For each module, classify the update:

| Status | Condition | Icon |
|--------|-----------|------|
| Current | `current == latest` | ✅ |
| Patch update | Major and minor match, patch differs | 🔄 |
| Minor update | Major matches, minor differs | 🔄 |
| Major update | Major version differs | ⚠️ |
| Failed | MCR query failed | ❌ |

### Step 5 — Review Breaking Changes

For **major** or **minor** version updates:

1. Fetch the module changelog/README from GitHub:
   `https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/{service}/{resource}`
2. Check for incompatible parameter changes, removed/renamed parameters, or
   behavioral changes.
3. If breaking changes are detected, **PAUSE and present them to the user**.
   Ask for explicit approval.

**Breaking Change Policy** — pause for approval when updates involve:

- Incompatible parameter changes (renamed, removed, type changed)
- Security or compliance modifications
- Behavioral changes affecting deployment outcomes

### Step 6 — Apply Updates

Run `Update-AvmVersions.ps1` / `update-avm-versions.sh` with a JSON array of
approved updates:

```json
[
  {
    "Module": "avm/res/storage/storage-account",
    "OldVersion": "0.9.0",
    "NewVersion": "0.14.0",
    "FilePath": "infra/main.bicep"
  }
]
```

**PowerShell** (Windows):

```powershell
$skillPath = Split-Path -Parent "<absolute-path-to-this-SKILL.md>"
$script = Join-Path $skillPath "scripts/Update-AvmVersions.ps1"
if (-not (Test-Path $script)) {
    Write-Error "FATAL: Script not found: $script — aborting workflow."
    exit 1
}
& $script -Updates '<json-array>'
# Or from a file:
& $script -UpdatesFile "updates.json"
```

**Shell** (macOS/Linux):

```bash
SKILL_PATH="$(dirname "<absolute-path-to-this-SKILL.md>")"
SCRIPT="$SKILL_PATH/scripts/update-avm-versions.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "FATAL: Script not found: $SCRIPT — aborting workflow." >&2
    exit 1
fi
"$SCRIPT" --file updates.json
# Or from stdin:
echo '<json-array>' | "$SCRIPT" --stdin
```

Outputs JSON results with status per module (`UPDATED`, `SKIPPED`, `FAILED`).

If breaking changes require parameter adjustments beyond the version bump,
apply those edits after the script completes.

### Step 7 — Validate

Run `Test-BicepBuild.ps1` / `test-bicep-build.sh` on all updated files.

**PowerShell** (Windows):

```powershell
$skillPath = Split-Path -Parent "<absolute-path-to-this-SKILL.md>"
$script = Join-Path $skillPath "scripts/Test-BicepBuild.ps1"
if (-not (Test-Path $script)) {
    Write-Error "FATAL: Script not found: $script — aborting workflow."
    exit 1
}
# Single file
& $script -BicepFile "<updated-file>"
# Multiple specific files
& $script -Files @("<file1>", "<file2>")
# Or entire directory
& $script -Directory "infra/"
```

**Shell** (macOS/Linux):

```bash
SKILL_PATH="$(dirname "<absolute-path-to-this-SKILL.md>")"
SCRIPT="$SKILL_PATH/scripts/test-bicep-build.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "FATAL: Script not found: $SCRIPT — aborting workflow." >&2
    exit 1
fi
# Single file
"$SCRIPT" --file "<updated-file>"
# Multiple files
"$SCRIPT" --files "<file1>" "<file2>"
# Or entire directory
"$SCRIPT" --directory "infra/"
```

Outputs JSON with `FilePath`, `Status`, `Message` per file. Exits with code 1
if any file fails.

If validation fails:

1. Report the specific error.
2. Attempt to fix parameter issues caused by the version change.
3. Re-validate using `Test-BicepBuild`.
4. If still failing, revert by running `Update-AvmVersions` with `OldVersion`
   and `NewVersion` swapped. Mark as ⚠️ in the results.

### Step 8 — Present Results

Display a summary table:

| Module | Current | Latest | Status | Action | Docs |
|--------|---------|--------|--------|--------|------|
| `avm/res/storage/storage-account` | 0.9.0 | 0.14.0 | 🔄 | Updated | [📖](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/storage/storage-account) |
| `avm/res/search/search-service` | 0.11.1 | 0.11.1 | ✅ | Current | [📖](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/search/search-service) |
| `avm/res/network/virtual-network` | 0.5.0 | 0.8.0 | ⚠️ | Manual review | [📖](https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/network/virtual-network) |

**Status Icons:**

- ✅ Current — already on latest version
- 🔄 Updated — successfully updated
- ⚠️ Manual review required — breaking changes need attention
- ❌ Failed — update could not be applied or validated

After the table, list modified files and remind the user to run
`az bicep build --file infra/main.bicep` for final end-to-end validation.

## MCR API Reference

### Tags List Endpoint

```text
GET https://mcr.microsoft.com/v2/bicep/avm/res/{service}/{resource}/tags/list
```

Returns JSON:

```json
{
  "name": "bicep/avm/res/storage/storage-account",
  "tags": ["0.6.0", "0.7.0", "0.8.0", "0.9.0", "0.14.0"]
}
```

### Module Path Mapping

| Bicep Reference | MCR Path |
|----------------|----------|
| `br/public:avm/res/storage/storage-account:0.14.0` | `bicep/avm/res/storage/storage-account` |
| `br/public:avm/ptn/ai-platform/baseline:0.1.0` | `bicep/avm/ptn/ai-platform/baseline` |

### GitHub Documentation

```text
https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/{service}/{resource}
```

## Edge Cases

- **Custom/local modules** (not `br/public:avm/`): Skip — only update AVM
  registry modules.
- **Pre-release tags**: Exclude tags containing `-` (e.g., `0.5.0-preview`).
- **Network errors**: If MCR is unreachable, report the error and skip that
  module rather than failing the entire run.
- **Multiple files referencing same module at different versions**: Update all
  to the same latest version for consistency.

## Validation Checklist

1. All bundled scripts were found and executed — no fallback occurred.
2. Summary table lists every `br/public:avm/` reference in the target file(s).
3. `Test-BicepBuild` reported zero failures for all updated modules.
