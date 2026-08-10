---
name: vscode-profile-sync

description: >-
  **WORKFLOW SKILL** — Replicate VS Code Insiders profiles and extensions
  into VS Code stable. Discovers profiles, diffs extensions, installs
  missing ones, optionally removes extras. Supports dry-run and selective
  sync. WHEN: \"sync VS Code profiles\", \"copy profiles from Insiders\",
  \"replicate Insiders profiles\", \"sync extensions to stable\",
  \"mirror Insiders profiles\". INVOKES: run_in_terminal for
  PowerShell/Shell. FOR SINGLE OPERATIONS: Use VS Code CLI directly.

compatibility: >-
  Requires both 'code-insiders' and 'code' CLI commands on PATH.
  PowerShell 7+ (Windows) or Bash (macOS/Linux).

metadata:
  author: PlagueHO
  version: "1.0"
---

# VS Code Profile Sync

Sync all VS Code Insiders profiles and their extensions to VS Code stable.
This skill reads profile definitions from VS Code Insiders, enumerates the
extensions in each profile, and replicates them into VS Code stable — creating
profiles that don't yet exist and installing any missing extensions. Only
extensions are synced; settings, keybindings, and other profile customizations
are not modified.

## Prerequisites

- **VS Code Insiders** installed with at least one custom profile configured.
- **VS Code stable** installed.
- Both `code-insiders` and `code` CLI commands available on `PATH`.
- **PowerShell 7+** (Windows) or **Bash** (macOS/Linux).

## Process

### Step 0 — Confirm Parameters

Before running, confirm these with the user:

| Parameter | Default | Description |
|-----------|---------|-------------|
| Source CLI | `code-insiders` | The source VS Code variant CLI command |
| Target CLI | `code` | The target VS Code variant CLI command |
| Profiles | All | Which profiles to sync (all or a comma-separated list) |
| Include Default | Yes | Whether to sync the Default profile extensions |
| Remove extras | No | Whether to uninstall extensions in the target that are not in the source |
| Dry run | No | Preview changes without applying them |

### Step 1 — Discover Source Profiles

Read the profile list from the source VS Code variant's `storage.json`:

**Windows path:**

```text
%APPDATA%\Code - Insiders\User\globalStorage\storage.json
```

**macOS path:**

```text
~/Library/Application Support/Code - Insiders/User/globalStorage/storage.json
```

**Linux path:**

```text
~/.config/Code - Insiders/User/globalStorage/storage.json
```

Parse the `userDataProfiles` array from this JSON file. Each entry contains:

- `name` — the human-readable profile name
- `location` — the internal directory name (not needed for CLI operations)

Add the implicit **Default** profile (which is not listed in the array).

If the user requested specific profiles, filter to only those names.

### Step 2 — Enumerate Extensions Per Profile

For each profile (including Default), list extensions using the source CLI:

```powershell
# For a named profile
code-insiders --list-extensions --profile "<profile-name>"

# For the Default profile
code-insiders --list-extensions --profile "Default"
```

Store the extension list for each profile.

### Step 3 — Create Missing Profiles in Target

VS Code stable **does not** auto-create profiles when installing extensions
with `--profile`. If a profile doesn't exist, the CLI returns "Profile 'X'
not found" and exits with code 1.

Before enumerating target extensions, create any missing profiles by:

1. Read the target's `storage.json` (`userDataProfiles` array).
2. For each source profile name not present in the target, copy its entry
   (name, location, icon, useDefaultFlags) from the source `storage.json`
   into the target `storage.json`.
3. Create the corresponding profile directory in the target's user data
   folder (e.g., `<UserData>/profiles/<location>/`).

The Default profile always exists and never needs to be created.

### Step 4 — Enumerate Target Extensions Per Profile

For each profile, list its current extensions in the target:

```powershell
code --list-extensions --profile "<profile-name>"
```

If the profile was just created, its extension list will be empty.

### Step 5 — Compute Differences

For each profile, compute:

- **To install**: extensions in source but not in target.
- **To remove** (if `Remove extras` is enabled): extensions in target but not
  in source.
- **Already synced**: extensions present in both.

Present a summary table to the user before proceeding:

```text
Profile: "Azure"
  Extensions in source: 25
  Extensions in target: 20
  To install: 5
  To remove: 0
  Already synced: 20
```

If `Dry run` is enabled, display the full list of changes and stop.

### Step 6 — Apply Changes

For each profile, install missing extensions and optionally remove extras:

```powershell
# Install missing extensions
code --install-extension <extension-id> --profile "<profile-name>"

# Remove extras (only if enabled)
code --uninstall-extension <extension-id> --profile "<profile-name>"
```

Run these commands using `run_in_terminal`. Install extensions sequentially
to avoid CLI conflicts (the VS Code CLI does not support parallel installs
reliably).

Alternatively, use the bundled scripts which handle the full workflow:

**PowerShell (Windows):**

```powershell
& "<skill-path>/scripts/Sync-VscodeProfiles.ps1" `
    -SourceCli "code-insiders" `
    -TargetCli "code" `
    -IncludeDefault `
    -DryRun
```

**Shell (macOS/Linux):**

```bash
"<skill-path>/scripts/sync-vscode-profiles.sh" \
    --source-cli "code-insiders" \
    --target-cli "code" \
    --include-default \
    --dry-run
```

### Step 7 — Verify

After syncing, verify by listing extensions in the target for each profile:

```powershell
code --list-extensions --profile "<profile-name>"
```

Compare the output to the source profile. All extension IDs should match.

Present a final summary:

```text
Sync complete:
  Profiles synced: 7 (Default + 6 custom)
  Extensions installed: 23
  Extensions removed: 0
  Errors: 0
```

## Edge Cases

- **Profile name with special characters**: Profile names may contain spaces,
  commas, and dots. Always quote profile names in CLI commands.
- **Extension not available in stable**: Some extensions may be Insiders-only
  (pre-release). If `code --install-extension` fails, log a warning and
  continue with the next extension.
- **Source and target are the same**: If both CLIs resolve to the same VS Code
  installation, warn the user and stop.
- **No custom profiles**: If the source has no custom profiles, sync only the
  Default profile extensions and inform the user.
- **storage.json not found**: If the storage.json file doesn't exist at the
  expected path, ask the user to confirm the source VS Code data directory.
- **Profiles not auto-created by stable CLI**: VS Code stable (unlike Insiders)
  does not create profiles on the fly via `--install-extension --profile`.
  The scripts handle this by pre-creating missing profiles in the target's
  `storage.json` and file system before installing extensions.
