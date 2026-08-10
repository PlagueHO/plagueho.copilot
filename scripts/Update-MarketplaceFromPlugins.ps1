<#
.SYNOPSIS
    Regenerates both marketplace indexes from source plugin manifests.

.DESCRIPTION
    Compatibility wrapper for the shared Node.js marketplace generator.

.PARAMETER RepoRoot
    Repository root. Defaults to the parent of the scripts directory.

.EXAMPLE
    .\Update-MarketplaceFromPlugins.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& node (Join-Path $RepoRoot 'eng/generate-marketplace.mjs') $RepoRoot
if ($LASTEXITCODE -ne 0) {
    throw "Marketplace generation failed with exit code $LASTEXITCODE."
}
