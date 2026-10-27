<#
.SYNOPSIS
    Check explicit skill paths without executing their contents.
.PARAMETER SkillPath
    One or more skill directories or SKILL.md files.
.PARAMETER Profile
    standard, or catalog to add local authoring checks.
.EXAMPLE
    ./check-frontmatter.ps1 -SkillPath ./skills/example -Profile catalog
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$SkillPath = @(),

    [string]$Profile = 'standard'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('Node.js 20+ is required. No checks ran.')
    exit 2
}

$arguments = @(
    (Join-Path $PSScriptRoot 'check-frontmatter.mjs'),
    '--profile', $Profile, '--'
) + $SkillPath
& node @arguments
exit $LASTEXITCODE
