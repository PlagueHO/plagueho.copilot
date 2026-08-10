<#
.SYNOPSIS
    Syncs VS Code profiles and extensions from one VS Code variant to another.

.DESCRIPTION
    Reads all profiles from a source VS Code variant (e.g., VS Code Insiders),
    enumerates extensions per profile, and installs missing extensions in the
    target VS Code variant (e.g., VS Code stable). Optionally removes extensions
    in the target that are not present in the source.

.PARAMETER SourceCli
    The CLI command for the source VS Code variant. Default: "code-insiders".

.PARAMETER TargetCli
    The CLI command for the target VS Code variant. Default: "code".

.PARAMETER Profiles
    Optional array of profile names to sync. If omitted, all profiles are synced.

.PARAMETER IncludeDefault
    Include the Default profile in the sync. Default: true.

.PARAMETER RemoveExtras
    Remove extensions from the target that are not in the source. Default: false.

.PARAMETER DryRun
    Preview changes without applying them. Default: false.

.EXAMPLE
    .\Sync-VscodeProfiles.ps1 -DryRun
    Preview what would be synced from VS Code Insiders to VS Code stable.

.EXAMPLE
    .\Sync-VscodeProfiles.ps1 -Profiles "Azure","Node.JS" -RemoveExtras
    Sync only the Azure and Node.JS profiles, removing extra extensions.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourceCli = 'code-insiders',

    [Parameter()]
    [string]$TargetCli = 'code',

    [Parameter()]
    [string[]]$Profiles,

    [Parameter()]
    [switch]$IncludeDefault = $true,

    [Parameter()]
    [switch]$RemoveExtras,

    [Parameter()]
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Test-CliAvailable {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Get-StorageJsonPath {
    param([string]$CliName)

    # Map CLI name to user data directory name
    $dirMap = @{
        'code-insiders' = 'Code - Insiders'
        'code'          = 'Code'
    }

    $dirName = $dirMap[$CliName]
    if (-not $dirName) {
        # Fallback: derive from CLI name
        $dirName = $CliName
    }

    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        return Join-Path $env:APPDATA "$dirName\User\globalStorage\storage.json"
    }
    elseif ($IsMacOS) {
        return Join-Path $HOME "Library/Application Support/$dirName/User/globalStorage/storage.json"
    }
    else {
        # Linux
        $configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
        return Join-Path $configDir "$dirName/User/globalStorage/storage.json"
    }
}

function Get-UserDataPath {
    param([string]$CliName)

    $dirMap = @{
        'code-insiders' = 'Code - Insiders'
        'code'          = 'Code'
    }

    $dirName = $dirMap[$CliName]
    if (-not $dirName) { $dirName = $CliName }

    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        return Join-Path $env:APPDATA "$dirName\User"
    }
    elseif ($IsMacOS) {
        return Join-Path $HOME "Library/Application Support/$dirName/User"
    }
    else {
        $configDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
        return Join-Path $configDir "$dirName/User"
    }
}

function Get-ProfileNames {
    param([string]$StorageJsonPath)

    if (-not (Test-Path $StorageJsonPath)) {
        Write-Error "Storage file not found: $StorageJsonPath"
        return @()
    }

    $storage = Get-Content $StorageJsonPath -Raw | ConvertFrom-Json
    $profileNames = @()

    if ($storage.PSObject.Properties['userDataProfiles']) {
        foreach ($profile in $storage.userDataProfiles) {
            $profileNames += $profile.name
        }
    }

    return $profileNames
}

function Get-ProfileEntries {
    param([string]$StorageJsonPath)

    if (-not (Test-Path $StorageJsonPath)) { return @() }

    $storage = Get-Content $StorageJsonPath -Raw | ConvertFrom-Json
    if ($storage.PSObject.Properties['userDataProfiles']) {
        return @($storage.userDataProfiles)
    }
    return @()
}

function Sync-ProfileDefinitions {
    param(
        [string]$SourceCli,
        [string]$TargetCli,
        [string[]]$ProfileNames
    )

    $sourceStoragePath = Get-StorageJsonPath -CliName $SourceCli
    $targetStoragePath = Get-StorageJsonPath -CliName $TargetCli
    $targetUserDataPath = Get-UserDataPath -CliName $TargetCli

    $sourceEntries = Get-ProfileEntries -StorageJsonPath $sourceStoragePath
    $targetStorage = Get-Content $targetStoragePath -Raw | ConvertFrom-Json

    $existingTargetEntries = @()
    if ($targetStorage.PSObject.Properties['userDataProfiles']) {
        $existingTargetEntries = @($targetStorage.userDataProfiles)
    }
    $existingNames = @($existingTargetEntries | ForEach-Object { $_.name })

    $created = 0
    $newEntries = [System.Collections.ArrayList]@($existingTargetEntries)

    foreach ($srcEntry in $sourceEntries) {
        if ($srcEntry.name -notin $ProfileNames) { continue }
        if ($srcEntry.name -in $existingNames) { continue }

        # Build a new entry matching the source structure
        $entry = [PSCustomObject]@{ location = $srcEntry.location; name = $srcEntry.name }
        if ($srcEntry.PSObject.Properties['icon']) {
            $entry | Add-Member -NotePropertyName 'icon' -NotePropertyValue $srcEntry.icon
        }
        if ($srcEntry.PSObject.Properties['useDefaultFlags']) {
            $entry | Add-Member -NotePropertyName 'useDefaultFlags' -NotePropertyValue $srcEntry.useDefaultFlags
        }
        [void]$newEntries.Add($entry)

        # Create the profile directory in the target
        $profileDir = Join-Path $targetUserDataPath "profiles\$($srcEntry.location)"
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }

        Write-Host "  Created profile: $($srcEntry.name)" -ForegroundColor Green
        $created++
    }

    if ($created -gt 0) {
        if ($targetStorage.PSObject.Properties['userDataProfiles']) {
            $targetStorage.userDataProfiles = @($newEntries)
        }
        else {
            $targetStorage | Add-Member -NotePropertyName 'userDataProfiles' -NotePropertyValue @($newEntries)
        }
        $targetStorage | ConvertTo-Json -Depth 10 | Set-Content $targetStoragePath -Encoding utf8NoBOM
    }

    return $created
}

function Get-ProfileExtensions {
    param(
        [string]$Cli,
        [string]$ProfileName
    )

    $args_ = @('--list-extensions', '--profile', $ProfileName)
    $output = & $Cli @args_ 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to list extensions for profile '$ProfileName' using $Cli. It may not exist yet."
        return @()
    }

    # Filter to non-empty lines and normalize to lowercase for comparison
    return @($output | Where-Object { $_ -and $_.Trim() } | ForEach-Object { $_.Trim().ToLower() })
}

# --- Validation ---

Write-Host "VS Code Profile Sync" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-CliAvailable $SourceCli)) {
    Write-Error "Source CLI '$SourceCli' not found on PATH. Install it or provide the full path."
    return
}

if (-not (Test-CliAvailable $TargetCli)) {
    Write-Error "Target CLI '$TargetCli' not found on PATH. Install it or provide the full path."
    return
}

# Quick check: are source and target different?
$sourceVersion = & $SourceCli --version 2>&1 | Select-Object -First 1
$targetVersion = & $TargetCli --version 2>&1 | Select-Object -First 1
Write-Host "Source: $SourceCli (version $sourceVersion)"
Write-Host "Target: $TargetCli (version $targetVersion)"
Write-Host ""

# --- Discover profiles ---

$storageJsonPath = Get-StorageJsonPath -CliName $SourceCli
Write-Host "Reading profiles from: $storageJsonPath" -ForegroundColor DarkGray

$allProfileNames = Get-ProfileNames -StorageJsonPath $storageJsonPath

if ($IncludeDefault) {
    $allProfileNames = @('Default') + $allProfileNames
}

# Filter if user specified specific profiles
if ($Profiles -and $Profiles.Count -gt 0) {
    $allProfileNames = @($allProfileNames | Where-Object { $_ -in $Profiles })
}

if ($allProfileNames.Count -eq 0) {
    Write-Warning "No profiles found to sync."
    return
}

Write-Host "Profiles to sync: $($allProfileNames -join ', ')" -ForegroundColor Green
Write-Host ""

# --- Create missing profiles in the target ---

$customProfilesToCreate = @($allProfileNames | Where-Object { $_ -ne 'Default' })
if ($customProfilesToCreate.Count -gt 0 -and -not $DryRun) {
    Write-Host "Ensuring profiles exist in target..." -ForegroundColor Cyan
    $createdCount = Sync-ProfileDefinitions -SourceCli $SourceCli -TargetCli $TargetCli -ProfileNames $customProfilesToCreate
    if ($createdCount -gt 0) {
        Write-Host "  $createdCount profile(s) created in target." -ForegroundColor Green
    }
    else {
        Write-Host "  All profiles already exist." -ForegroundColor DarkGray
    }
    Write-Host ""
}
elseif ($customProfilesToCreate.Count -gt 0 -and $DryRun) {
    # Check which profiles would need creation
    $targetStoragePath = Get-StorageJsonPath -CliName $TargetCli
    $existingTargetNames = @()
    if (Test-Path $targetStoragePath) {
        $ts = Get-Content $targetStoragePath -Raw | ConvertFrom-Json
        if ($ts.PSObject.Properties['userDataProfiles']) {
            $existingTargetNames = @($ts.userDataProfiles | ForEach-Object { $_.name })
        }
    }
    $missing = @($customProfilesToCreate | Where-Object { $_ -notin $existingTargetNames })
    if ($missing.Count -gt 0) {
        Write-Host "Profiles to create in target (dry run):" -ForegroundColor Magenta
        foreach ($m in $missing) { Write-Host "  + $m" -ForegroundColor Magenta }
        Write-Host ""
    }
}

# --- Enumerate and compute differences ---

$totalInstalled = 0
$totalRemoved = 0
$totalErrors = 0

foreach ($profileName in $allProfileNames) {
    Write-Host "--- Profile: $profileName ---" -ForegroundColor Yellow

    $sourceExts = @(Get-ProfileExtensions -Cli $SourceCli -ProfileName $profileName)
    $targetExts = @(Get-ProfileExtensions -Cli $TargetCli -ProfileName $profileName)

    $toInstall = @($sourceExts | Where-Object { $_ -notin $targetExts })
    $toRemove = @(if ($RemoveExtras) { $targetExts | Where-Object { $_ -notin $sourceExts } } else { @() })
    $alreadySynced = @($sourceExts | Where-Object { $_ -in $targetExts })

    Write-Host "  Source extensions: $($sourceExts.Count)"
    Write-Host "  Target extensions: $($targetExts.Count)"
    Write-Host "  To install: $($toInstall.Count)" -ForegroundColor $(if ($toInstall.Count -gt 0) { 'Cyan' } else { 'DarkGray' })
    Write-Host "  To remove: $($toRemove.Count)" -ForegroundColor $(if ($toRemove.Count -gt 0) { 'Red' } else { 'DarkGray' })
    Write-Host "  Already synced: $($alreadySynced.Count)" -ForegroundColor DarkGray

    if ($toInstall.Count -gt 0) {
        Write-Host "  Extensions to install:" -ForegroundColor Cyan
        foreach ($ext in $toInstall) { Write-Host "    + $ext" -ForegroundColor Cyan }
    }

    if ($toRemove.Count -gt 0) {
        Write-Host "  Extensions to remove:" -ForegroundColor Red
        foreach ($ext in $toRemove) { Write-Host "    - $ext" -ForegroundColor Red }
    }

    if ($DryRun) {
        Write-Host "  [DRY RUN] No changes applied." -ForegroundColor Magenta
        Write-Host ""
        continue
    }

    # Install missing extensions
    foreach ($ext in $toInstall) {
        Write-Host "  Installing: $ext" -ForegroundColor Cyan -NoNewline
        $installOutput = & $TargetCli --install-extension $ext --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            $totalInstalled++
        }
        else {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Warning "    $installOutput"
            $totalErrors++
        }
    }

    # Remove extra extensions
    foreach ($ext in $toRemove) {
        Write-Host "  Removing: $ext" -ForegroundColor Red -NoNewline
        $removeOutput = & $TargetCli --uninstall-extension $ext --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green
            $totalRemoved++
        }
        else {
            Write-Host " FAILED" -ForegroundColor Red
            Write-Warning "    $removeOutput"
            $totalErrors++
        }
    }

    Write-Host ""
}

# --- Summary ---

Write-Host "=====================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "Dry run complete. No changes were applied." -ForegroundColor Magenta
}
else {
    Write-Host "Sync complete:" -ForegroundColor Green
    Write-Host "  Profiles synced: $($allProfileNames.Count)"
    Write-Host "  Extensions installed: $totalInstalled"
    Write-Host "  Extensions removed: $totalRemoved"
    Write-Host "  Errors: $totalErrors" -ForegroundColor $(if ($totalErrors -gt 0) { 'Red' } else { 'Green' })
}
