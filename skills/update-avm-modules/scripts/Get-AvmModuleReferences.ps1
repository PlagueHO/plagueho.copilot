<#
.SYNOPSIS
    Extracts Azure Verified Module (AVM) references from Bicep files.

.DESCRIPTION
    Scans one or more Bicep files for AVM module references matching
    br/public:avm/{type}/{service}/{resource}:{version} and outputs
    structured JSON with module path, current version, file path, and
    line number for each reference.

.PARAMETER BicepFile
    Path to a single Bicep file to scan.

.PARAMETER Directory
    Path to a directory to recursively scan for *.bicep files.

.EXAMPLE
    .\Get-AvmModuleReferences.ps1 -BicepFile "infra/main.bicep"

.EXAMPLE
    .\Get-AvmModuleReferences.ps1 -Directory "infra/"
#>

[CmdletBinding(DefaultParameterSetName = 'File')]
param(
    [Parameter(Mandatory, ParameterSetName = 'File')]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$BicepFile,

    [Parameter(Mandatory, ParameterSetName = 'Directory')]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Directory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pattern = "br/public:(avm/(?:res|ptn|utl)/[^:]+):(\d+\.\d+(?:\.\d+)?)"

# Determine files to scan
if ($PSCmdlet.ParameterSetName -eq 'Directory') {
    $files = Get-ChildItem -Path $Directory -Recurse -Filter '*.bicep' -File |
        Select-Object -ExpandProperty FullName
} else {
    $files = @((Resolve-Path $BicepFile).Path)
}

if ($files.Count -eq 0) {
    Write-Host "No Bicep files found."
    Write-Output "[]"
    exit 0
}

$results = @()

foreach ($file in $files) {
    $lines = Get-Content -Path $file
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineMatches = [regex]::Matches($line, $pattern)

        foreach ($match in $lineMatches) {
            $results += [PSCustomObject]@{
                Module      = $match.Groups[1].Value
                Version     = $match.Groups[2].Value
                FilePath    = $file
                LineNumber  = $i + 1
            }
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No AVM module references found."
    Write-Output "[]"
    exit 0
}

Write-Host "Found $($results.Count) AVM module reference(s) in $($files.Count) file(s)."
$results | ConvertTo-Json -Depth 3
