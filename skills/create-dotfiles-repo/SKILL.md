---
name: create-dotfiles-repo

description: >-
  **WORKFLOW SKILL** — Scaffold a dotfiles template repository in a GitHub
  Organization from an existing workspace. Scans for shell, git, editor, and
  package configs; interviews the user via vscode_askQuestions; generates
  bootstrap installers. WHEN: "create dotfiles repo", "dotfiles from
  project", "generate dotfiles", "bootstrap dotfiles", "dotfiles template
  repo", "export dotfiles". INVOKES: run_in_terminal, vscode_askQuestions,
  gh CLI. FOR SINGLE OPERATIONS: Manually copy config files.

metadata:
  author: PlagueHO
  version: "1.0"
---

# Create Dotfiles Repo

Create a dotfiles template repository in a GitHub Organization by scanning an
existing project or workspace for configuration files, interviewing the user
about what to include, and scaffolding a well-organized dotfiles repo with a
bootstrap installer. The resulting repo follows community best practices from
[dotfiles.github.io](https://dotfiles.github.io/) and is marked as a GitHub
template repository.

## Prerequisites

- **Git** — installed and authenticated with GitHub.
- **GitHub CLI (`gh`)** — installed and authenticated (`gh auth status`).
  Required to create the repository in the target organization.
- **PowerShell 7+** (Windows) or **Bash** (macOS/Linux) — for running the
  scanner script.
- The user must have permission to create repositories in the target GitHub
  Organization.

## Process

### Step 0 — Gather Context

Before starting, collect the following from the user or conversation history:

1. **Source workspace path** — the repo or project to extract dotfiles from.
   Default to the current workspace root.
2. **Target GitHub Organization** — where the dotfiles repo will be created.
3. **Repo name** — default `dotfiles` (the GitHub convention).
4. **Repo visibility** — public or private. Default public.
5. **Organization style** — flat (all files at root) or topical (grouped by
   tool in subdirectories). Default topical.

If any of these are missing, use `vscode_askQuestions` to ask:

```text
Questions:
1. Which GitHub Organization should the dotfiles repo be created in?
2. What should the repository be named? (default: dotfiles)
3. Should it be public or private? (default: public)
4. Prefer flat layout (all files at root) or topical layout (grouped by
   tool in subdirectories like git/, shell/, editor/)? (default: topical)
```

### Step 1 — Scan for Dotfile Candidates

Run the scanner script to discover configuration files in the source workspace.
The scripts are bundled in this skill's `scripts/` directory.

**PowerShell** (Windows):

```powershell
& "<skill-path>/scripts/Scan-Dotfiles.ps1" -Path "<workspace-root>"
```

**Shell** (macOS/Linux):

```bash
"<skill-path>/scripts/scan-dotfiles.sh" "<workspace-root>"
```

The scanner searches for files in these categories:

| Category | Files / Patterns |
|----------|-----------------|
| **Shell** | `.bashrc`, `.bash_profile`, `.zshrc`, `.zprofile`, `.profile`, `.zshenv`, `.aliases`, `.functions`, `.inputrc`, `.hushlogin` |
| **Git** | `.gitconfig`, `.gitignore_global`, `.gitattributes`, `.gitmessage`, `.gittemplate` |
| **Editor** | `.vimrc`, `.editorconfig`, `.nanorc`, `settings.json` (VS Code) |
| **SSH** | `.ssh/config` (never keys) |
| **Package managers** | `Brewfile`, `.npmrc`, `.yarnrc`, `.nuget/NuGet.Config`, `pip.conf` |
| **OS preferences** | `.macos`, `.Xresources`, `.xprofile` |
| **Terminal** | `.tmux.conf`, `.screenrc`, `.wezterm.lua`, `.hyper.js`, Windows Terminal `settings.json` |
| **Language runtimes** | `.gemrc`, `.irbrc`, `.pryrc`, `.pylintrc`, `.flake8`, `.prettierrc`, `.eslintrc.*` |
| **Prompt** | `.p10k.zsh`, `.starship.toml`, `oh-my-posh` themes |

Collect the results into a categorized list.

### Step 2 — Interview the User

Present the discovered files grouped by category. Use `vscode_askQuestions` to
confirm inclusion. For each file, if there is a reason the agent thinks the
file should be omitted (e.g., contains environment-specific paths, references
machine-local tools, includes sensitive-looking values), explain the concern
and recommend exclusion.

Example question flow:

```text
I found the following dotfile candidates in your workspace:

**Shell (4 files)**
- .bashrc ✅ recommended
- .bash_profile ✅ recommended
- .zshrc ✅ recommended
- .profile ⚠️ contains hardcoded /home/username paths — recommend review

**Git (2 files)**
- .gitconfig ✅ recommended
- .gitignore_global ✅ recommended

**Editor (1 file)**
- .editorconfig ✅ recommended

Questions:
1. Should I include all recommended files? (yes/no)
2. For flagged files, should I include them as-is, sanitize them
   (replace machine-specific values with placeholders), or skip them?
3. Are there any additional files not listed that you want to include?
```

Apply the user's choices to build the final file manifest.

### Step 3 — Sanitize Sensitive Content

For each included file, scan for potential secrets or machine-specific values:

- **Tokens / API keys** — strings matching common patterns (`ghp_`, `sk-`,
  `AKIA`, `xox-`, bearer tokens).
- **Hardcoded home paths** — replace `/home/<username>` or
  `C:\Users\<username>` with `$HOME` or `%USERPROFILE%` placeholders.
- **Email addresses in gitconfig** — leave but flag for the user to confirm.
- **Private keys** — never include. If `.ssh/config` references key paths,
  replace with `~/.ssh/<keyname>` placeholder.

If any sensitive content is found, use `vscode_askQuestions` to confirm the
sanitization approach before proceeding.

### Step 4 — Scaffold the Dotfiles Repo

Create a local directory for the new dotfiles repo and populate it.

#### Topical Layout (default)

```text
dotfiles/
├── README.md              # Overview, install instructions, file inventory
├── install.sh             # Bootstrap script (symlinks + package install)
├── install.ps1            # Bootstrap script (Windows/PowerShell)
├── git/
│   ├── .gitconfig
│   └── .gitignore_global
├── shell/
│   ├── .bashrc
│   ├── .bash_profile
│   ├── .zshrc
│   └── .aliases
├── editor/
│   └── .editorconfig
├── terminal/
│   └── .tmux.conf
├── macos/
│   └── .macos
└── packages/
    └── Brewfile
```

#### Flat Layout

```text
dotfiles/
├── README.md
├── install.sh
├── install.ps1
├── .bashrc
├── .zshrc
├── .gitconfig
├── .editorconfig
└── Brewfile
```

Copy each file from the source to its target location in the new repo,
applying any sanitization from Step 3.

### Step 5 — Generate the Bootstrap Installer

Create `install.sh` and `install.ps1` at the repo root. The installers:

1. Detect the OS (macOS, Linux, Windows).
2. Symlink each dotfile from the repo to the user's home directory. Back up
   any existing file to `~/.dotfiles-backup/<timestamp>/` first.
3. Optionally install packages from `Brewfile` (macOS/Linux) or
   `winget`/`choco` (Windows) if present.
4. Source shell configuration to apply changes.

The install script should:

- Be idempotent (safe to run multiple times).
- Print clear output about each action taken.
- Support a `--dry-run` flag that shows what would be done without making
  changes.

#### Shell installer template

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d%H%M%S)"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

link_file() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    $DRY_RUN && echo "[dry-run] Would backup $dst" && return
    mv "$dst" "$BACKUP_DIR/$(basename "$dst")"
    echo "Backed up $dst"
  fi
  $DRY_RUN && echo "[dry-run] Would link $src -> $dst" && return
  ln -sf "$src" "$dst"
  echo "Linked $src -> $dst"
}

# Symlink each dotfile — adapt paths per layout
# Example for topical layout:
# link_file "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
```

#### PowerShell installer template

```powershell
#!/usr/bin/env pwsh
[CmdletBinding()]
param([switch]$DryRun)

$DotfilesDir = $PSScriptRoot
$BackupDir = Join-Path $HOME ".dotfiles-backup/$(Get-Date -Format 'yyyyMMddHHmmss')"

function Link-File {
  param([string]$Source, [string]$Destination)
  if (Test-Path $Destination) {
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    if ($DryRun) { Write-Host "[dry-run] Would backup $Destination"; return }
    Move-Item $Destination (Join-Path $BackupDir (Split-Path $Destination -Leaf))
    Write-Host "Backed up $Destination"
  }
  if ($DryRun) { Write-Host "[dry-run] Would link $Source -> $Destination"; return }
  New-Item -ItemType SymbolicLink -Path $Destination -Target $Source -Force | Out-Null
  Write-Host "Linked $Source -> $Destination"
}

# Symlink each dotfile — adapt paths per layout
# Example for topical layout:
# Link-File "$DotfilesDir\git\.gitconfig" "$HOME\.gitconfig"
```

Populate the actual `link_file` / `Link-File` calls based on the files
included in Step 2.

### Step 6 — Generate README.md

Create a `README.md` that includes:

1. **Title and description** — what these dotfiles configure.
2. **Quick start** — clone + run the install script.
3. **File inventory** — table of every included file, its category, and what
   it configures.
4. **Customization** — how to add or remove dotfiles.
5. **Maintenance tips** — keep the repo updated when local configs change
   (reference dotfiles.github.io best practices).
6. **Credits** — link to dotfiles.github.io and any bootstrap repos that
   inspired the structure.

### Step 7 — Create the GitHub Repository

Use the GitHub CLI to create the repo in the target organization:

```bash
cd <local-dotfiles-directory>
git init
git add -A
git commit -m "Initial dotfiles from <source-repo-name>"
gh repo create <org>/<repo-name> \
  --public \
  --source . \
  --push \
  --description "Personal dotfiles — bootstrapped from <source-repo-name>"
```

Then mark it as a template repository:

```bash
gh repo edit <org>/<repo-name> --template
```

If the user chose private visibility, replace `--public` with `--private`.

### Step 8 — Verify and Present

Confirm the repository was created successfully:

```bash
gh repo view <org>/<repo-name> --json name,url,isTemplate
```

Present the user with:

1. The repository URL.
2. A summary of included files by category.
3. Instructions to clone and run the installer on a new machine.
4. Any files that were skipped and why.

## Edge Cases

- **No dotfiles found** — If the scanner finds no candidates, inform the user
  and offer to create a minimal dotfiles repo with just `.gitconfig` and
  `.editorconfig` templates.
- **Repo already exists** — If `<org>/dotfiles` already exists, ask the user
  whether to choose a different name, overwrite, or abort.
- **Secrets detected** — If sanitization cannot safely remove a secret (e.g.,
  inline in a complex config), skip the file and explain why.
- **Windows-only workspace** — Adjust the scanner to also look for Windows
  Terminal settings, PowerShell profile (`$PROFILE`), and Windows-specific
  configs. Generate only `install.ps1` if no Unix shell configs exist.
- **Mixed OS configs** — Include both and let the install scripts detect the
  OS at runtime.
- **Large files** — Skip any file over 100 KB with a warning.

## Validation

1. Verify the GitHub repo exists and is marked as a template.
2. Clone the repo to a temp directory and confirm `install.sh` and/or
   `install.ps1` run without errors in `--dry-run` mode.
3. Confirm no secrets or private keys are present in any committed file.
4. Confirm README.md includes the file inventory table.

## Reference

Detailed best practices compiled from community tutorials are in
[references/DOTFILES-GUIDE.md](references/DOTFILES-GUIDE.md).
