<#
.SYNOPSIS
    Applies version updates to AVM module references in Bicep files.

.DESCRIPTION
    Takes a JSON array of update operations and applies them to Bicep files.
    Each operation specifies a module path, old version, new version, and
    the target file. Performs exact string replacement of the version in the
    module reference line.

.PARAMETER Updates
    JSON string containing an array of update objects. Each object must have:
    - Module: The AVM module path (e.g., "avm/res/storage/storage-account")
    - OldVersion: The current version string (e.g., "0.9.0")
    - NewVersion: The target version string (e.g., "0.14.0")
    - FilePath: Absolute path to the Bicep file

.PARAMETER UpdatesFile
    Path to a JSON file containing the updates array (alternative to -Updates).

.EXAMPLE
    .\Update-AvmVersions.ps1 -Updates '[{"Module":"avm/res/storage/storage-account","OldVersion":"0.9.0","NewVersion":"0.14.0","FilePath":"infra/main.bicep"}]'

.EXAMPLE
    .\Update-AvmVersions.ps1 -UpdatesFile "updates.json"
#>

[CmdletBinding(DefaultParameterSetName = 'Inline')]
param(
    [Parameter(Mandatory, ParameterSetName = 'Inline')]
    [string]$Updates,

    [Parameter(Mandatory, ParameterSetName = 'File')]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$UpdatesFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Parse updates
if ($PSCmdlet.ParameterSetName -eq 'File') {
    $updateList = Get-Content -Path $UpdatesFile -Raw | ConvertFrom-Json
} else {
    $updateList = $Updates | ConvertFrom-Json
}

if ($null -eq $updateList -or $updateList.Count -eq 0) {
    Write-Host "No updates to apply."
    Write-Output "[]"
    exit 0
}

$results = @()

foreach ($update in $updateList) {
    $module = $update.Module
    $oldVersion = $update.OldVersion
    $newVersion = $update.NewVersion
    $filePath = $update.FilePath

    if (-not (Test-Path $filePath -PathType Leaf)) {
        $results += [PSCustomObject]@{
            Module     = $module
            OldVersion = $oldVersion
            NewVersion = $newVersion
            FilePath   = $filePath
            Status     = "FAILED"
            Message    = "File not found"
        }
        continue
    }

    $content = Get-Content -Path $filePath -Raw
    $searchPattern = "br/public:${module}:${oldVersion}"
    $replacePattern = "br/public:${module}:${newVersion}"

    $occurrences = ([regex]::Matches($content, [regex]::Escape($searchPattern))).Count

    if ($occurrences -eq 0) {
        $results += [PSCustomObject]@{
            Module     = $module
            OldVersion = $oldVersion
            NewVersion = $newVersion
            FilePath   = $filePath
            Status     = "SKIPPED"
            Message    = "Reference not found in file"
        }
        continue
    }

    $updatedContent = $content.Replace($searchPattern, $replacePattern)
    Set-Content -Path $filePath -Value $updatedContent -NoNewline

    $results += [PSCustomObject]@{
        Module     = $module
        OldVersion = $oldVersion
        NewVersion = $newVersion
        FilePath   = $filePath
        Status     = "UPDATED"
        Message    = "Replaced $occurrences occurrence(s)"
    }
}

# Summary
$updatedCount = @($results | Where-Object { $_.Status -eq 'UPDATED' }).Count
$skippedCount = @($results | Where-Object { $_.Status -eq 'SKIPPED' }).Count
$failedCount = @($results | Where-Object { $_.Status -eq 'FAILED' }).Count

Write-Host ""
Write-Host "Update Results: $updatedCount updated, $skippedCount skipped, $failedCount failed"
Write-Host ""

$results | ConvertTo-Json -Depth 3
