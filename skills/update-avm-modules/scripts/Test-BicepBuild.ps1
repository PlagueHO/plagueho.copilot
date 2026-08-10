<#
.SYNOPSIS
    Validates Bicep files using az bicep build.

.DESCRIPTION
    Runs az bicep build against one or more Bicep files and reports
    pass/fail status for each. Outputs structured JSON results.

.PARAMETER BicepFile
    Path to a single Bicep file to validate.

.PARAMETER Directory
    Path to a directory to recursively validate all *.bicep files.

.PARAMETER Files
    Array of specific file paths to validate.

.EXAMPLE
    .\Test-BicepBuild.ps1 -BicepFile "infra/main.bicep"

.EXAMPLE
    .\Test-BicepBuild.ps1 -Directory "infra/"

.EXAMPLE
    .\Test-BicepBuild.ps1 -Files @("infra/main.bicep", "infra/modules/storage.bicep")
#>

[CmdletBinding(DefaultParameterSetName = 'File')]
param(
    [Parameter(Mandatory, ParameterSetName = 'File')]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$BicepFile,

    [Parameter(Mandatory, ParameterSetName = 'Directory')]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Directory,

    [Parameter(Mandatory, ParameterSetName = 'List')]
    [string[]]$Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Verify az CLI is available
if (-not (Get-Command 'az' -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI (az) is not installed or not in PATH."
    exit 1
}

# Determine files to validate
switch ($PSCmdlet.ParameterSetName) {
    'File' {
        $targetFiles = @((Resolve-Path $BicepFile).Path)
    }
    'Directory' {
        $targetFiles = Get-ChildItem -Path $Directory -Recurse -Filter '*.bicep' -File |
            Select-Object -ExpandProperty FullName
    }
    'List' {
        $targetFiles = $Files | ForEach-Object {
            if (Test-Path $_ -PathType Leaf) {
                (Resolve-Path $_).Path
            } else {
                Write-Warning "File not found, skipping: $_"
                $null
            }
        } | Where-Object { $null -ne $_ }
    }
}

if ($targetFiles.Count -eq 0) {
    Write-Host "No Bicep files to validate."
    Write-Output "[]"
    exit 0
}

Write-Host "Validating $($targetFiles.Count) Bicep file(s)..."
Write-Host ""

$results = @()

foreach ($file in $targetFiles) {
    $output = $null
    $exitCode = 0

    try {
        $output = az bicep build --file $file 2>&1
        $exitCode = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $exitCode = 1
    }

    if ($exitCode -eq 0) {
        $status = "PASSED"
        $message = "Validation successful"
        Write-Host "  PASS: $file"
    } else {
        $status = "FAILED"
        $message = ($output | Out-String).Trim()
        Write-Host "  FAIL: $file"
        Write-Host "        $message"
    }

    # Clean up generated ARM template if az bicep build created one
    $armFile = [System.IO.Path]::ChangeExtension($file, '.json')
    if ((Test-Path $armFile) -and $status -eq 'PASSED') {
        Remove-Item -Path $armFile -Force -ErrorAction SilentlyContinue
    }

    $results += [PSCustomObject]@{
        FilePath = $file
        Status   = $status
        Message  = $message
    }
}

Write-Host ""

$passedCount = @($results | Where-Object { $_.Status -eq 'PASSED' }).Count
$failedCount = @($results | Where-Object { $_.Status -eq 'FAILED' }).Count

Write-Host "Validation Results: $passedCount passed, $failedCount failed"
Write-Host ""

$results | ConvertTo-Json -Depth 3

if ($failedCount -gt 0) {
    exit 1
}
