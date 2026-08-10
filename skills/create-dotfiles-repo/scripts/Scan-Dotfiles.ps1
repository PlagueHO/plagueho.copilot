<#
.SYNOPSIS
    Scans a directory tree for common dotfile and configuration file candidates.

.DESCRIPTION
    Searches the specified directory (defaults to $HOME) for known dotfiles and
    configuration files grouped by category (shell, git, editor, SSH, terminal,
    packages, OS preferences, prompt, language runtimes). Outputs a categorized
    list of discovered files suitable for inclusion in a dotfiles repository.

    Files are checked at the target Path root and common subdirectories. SSH
    private keys are explicitly excluded for security.

.PARAMETER Path
    The root directory to scan. Defaults to the user's home directory ($HOME).

.PARAMETER IncludeVSCode
    Also scan for VS Code settings.json and keybindings.json.

.PARAMETER OutputFormat
    Output format: 'table' (human-readable) or 'json' (machine-readable).
    Defaults to 'table'.

.EXAMPLE
    .\Scan-Dotfiles.ps1 -Path "C:\Users\me"

.EXAMPLE
    .\Scan-Dotfiles.ps1 -Path "/home/me" -OutputFormat json
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = $HOME,

    [Parameter()]
    [switch]$IncludeVSCode,

    [Parameter()]
    [ValidateSet('table', 'json')]
    [string]$OutputFormat = 'table'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $Path)) {
    Write-Error "Path '$Path' does not exist."
    return
}

# Define file patterns by category
$categories = [ordered]@{
    'Shell' = @(
        '.bashrc', '.bash_profile', '.bash_logout', '.zshrc', '.zprofile',
        '.zshenv', '.zlogout', '.profile', '.aliases', '.functions',
        '.inputrc', '.hushlogin', '.exports'
    )
    'Git' = @(
        '.gitconfig', '.gitignore_global', '.gitattributes', '.gitmessage',
        '.gittemplate'
    )
    'Editor' = @(
        '.vimrc', '.vim', '.editorconfig', '.nanorc', '.emacs', '.emacs.d'
    )
    'SSH' = @(
        '.ssh/config'
    )
    'Terminal' = @(
        '.tmux.conf', '.screenrc', '.wezterm.lua', '.hyper.js',
        '.alacritty.yml', '.alacritty.toml'
    )
    'Package Managers' = @(
        'Brewfile', '.npmrc', '.yarnrc', '.yarnrc.yml',
        '.gemrc', 'pip.conf', '.pip/pip.conf', '.config/pip/pip.conf'
    )
    'OS Preferences' = @(
        '.macos', '.Xresources', '.xprofile', '.xinitrc'
    )
    'Prompt' = @(
        '.p10k.zsh', '.starship.toml', '.config/starship.toml'
    )
    'Language Runtimes' = @(
        '.irbrc', '.pryrc', '.pylintrc', '.flake8', '.prettierrc',
        '.prettierrc.json', '.prettierrc.yml', '.eslintrc',
        '.eslintrc.json', '.eslintrc.yml', '.eslintrc.js',
        '.rubocop.yml', '.python-version', '.node-version',
        '.nvmrc', '.ruby-version', '.tool-versions'
    )
    'PowerShell' = @(
        'Documents/PowerShell/Microsoft.PowerShell_profile.ps1',
        'Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1',
        '.config/powershell/Microsoft.PowerShell_profile.ps1'
    )
}

if ($IncludeVSCode) {
    $categories['VS Code'] = @(
        '.config/Code/User/settings.json',
        '.config/Code/User/keybindings.json',
        'AppData/Roaming/Code/User/settings.json',
        'AppData/Roaming/Code/User/keybindings.json',
        '.config/Code - Insiders/User/settings.json',
        'AppData/Roaming/Code - Insiders/User/settings.json'
    )
}

# SSH key patterns to NEVER include
$sshKeyPatterns = @(
    'id_rsa', 'id_rsa.pub', 'id_ed25519', 'id_ed25519.pub',
    'id_ecdsa', 'id_ecdsa.pub', 'id_dsa', 'id_dsa.pub',
    'known_hosts', 'authorized_keys'
)

$results = [System.Collections.ArrayList]::new()

foreach ($category in $categories.GetEnumerator()) {
    foreach ($filePattern in $category.Value) {
        $fullPath = Join-Path -Path $Path -ChildPath $filePattern

        if (Test-Path -Path $fullPath) {
            $item = Get-Item -Path $fullPath -Force
            $sizeKB = if ($item.PSIsContainer) { 'dir' } else { [math]::Round($item.Length / 1KB, 1) }

            # Security check
            $warning = $null
            if ($category.Key -eq 'SSH') {
                $sshDir = Join-Path -Path $Path -ChildPath '.ssh'
                if (Test-Path $sshDir) {
                    $keyFiles = Get-ChildItem -Path $sshDir -Force |
                        Where-Object { $sshKeyPatterns -contains $_.Name }
                    if ($keyFiles) {
                        $warning = 'SSH keys found in .ssh/ — only config will be included'
                    }
                }
            }

            # Check for potential secrets in file content
            if (-not $item.PSIsContainer -and $item.Length -lt 102400) {
                $content = Get-Content -Path $fullPath -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    if ($content -match '(ghp_|sk-|AKIA|xox-|bearer\s|password\s*=|token\s*=)') {
                        $warning = 'Potential secret or token detected — review before including'
                    }
                    elseif ($content -match '(/home/\w+|/Users/\w+|C:\\Users\\\w+)') {
                        $warning = $warning ?? 'Contains hardcoded user paths — recommend sanitization'
                    }
                }
            }

            # Skip files over 100 KB
            if (-not $item.PSIsContainer -and $item.Length -gt 102400) {
                $warning = "File is $([math]::Round($item.Length / 1KB))KB — exceeds 100KB limit, will be skipped"
            }

            [void]$results.Add([PSCustomObject]@{
                Category    = $category.Key
                File        = $filePattern
                FullPath    = $fullPath
                SizeKB      = $sizeKB
                Warning     = $warning
                Recommended = if ($warning -match 'secret|skip') { $false } else { $true }
            })
        }
    }
}

# Output
if ($results.Count -eq 0) {
    Write-Host "No dotfile candidates found in '$Path'." -ForegroundColor Yellow
    return
}

if ($OutputFormat -eq 'json') {
    $results | ConvertTo-Json -Depth 3
}
else {
    Write-Host "`nDotfile candidates found in: $Path`n" -ForegroundColor Cyan

    $grouped = $results | Group-Object -Property Category
    foreach ($group in $grouped) {
        Write-Host "  $($group.Name) ($($group.Count) files)" -ForegroundColor Green
        foreach ($file in $group.Group) {
            $icon = if ($file.Recommended) { '  ✅' } else { '  ⚠️' }
            $line = "    $icon $($file.File)"
            if ($file.SizeKB -ne 'dir') {
                $line += " ($($file.SizeKB) KB)"
            }
            Write-Host $line
            if ($file.Warning) {
                Write-Host "       ⤷ $($file.Warning)" -ForegroundColor Yellow
            }
        }
        Write-Host ''
    }

    Write-Host "Total: $($results.Count) candidates found." -ForegroundColor Cyan
}
