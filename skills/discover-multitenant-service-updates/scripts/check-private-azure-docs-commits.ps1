<#
.SYNOPSIS
    Queries path-scoped commit history in a private Azure documentation repository.

.DESCRIPTION
    Invokes the Python helper using the user's authenticated GitHub CLI.
    Does not clone or update documentation repositories.

.PARAMETER Repository
    Supported MicrosoftDocs repository.

.PARAMETER Section
    Exact product section path beneath articles/. May be repeated.

.PARAMETER Since
    Last-updated date in YYYY-MM-DD format.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('MicrosoftDocs/azure-ai-docs-pr', 'MicrosoftDocs/azure-docs-pr')]
    [string]$Repository,

    [Parameter(Mandatory)]
    [string[]]$Section,

    [Parameter(Mandatory)]
    [string]$Since
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$arguments = @(
    (Join-Path $PSScriptRoot 'check-private-azure-docs-commits.py'),
    '--repository', $Repository,
    '--since', $Since
)
foreach ($sectionPath in $Section) {
    $arguments += @('--section', $sectionPath)
}

$pythonCommand = $null
$pythonPrefix = @()

$pythonLauncher = Get-Command py -ErrorAction SilentlyContinue
if ($pythonLauncher) {
    $version = & $pythonLauncher.Source -3 --version 2>&1
    if ($LASTEXITCODE -eq 0 -and "$version" -match 'Python 3\.') {
        $pythonCommand = $pythonLauncher.Source
        $pythonPrefix = @('-3')
    }
}

if (-not $pythonCommand) {
    foreach ($commandName in @('python3', 'python')) {
        $pythonLauncher = Get-Command $commandName -ErrorAction SilentlyContinue
        if (-not $pythonLauncher) {
            continue
        }
        $version = & $pythonLauncher.Source --version 2>&1
        if ($LASTEXITCODE -eq 0 -and "$version" -match 'Python 3\.') {
            $pythonCommand = $pythonLauncher.Source
            break
        }
    }
}

if (-not $pythonCommand) {
    $uvLauncher = Get-Command uv -ErrorAction SilentlyContinue
    if ($uvLauncher) {
        $candidate = & $uvLauncher.Source python find 3.13 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $candidate)) {
            $pythonCommand = $candidate
        }
    }
}

if (-not $pythonCommand) {
    throw 'Python 3 was not found. Install Python 3 or add it to PATH.'
}

$pythonArguments = @($pythonPrefix) + $arguments
& $pythonCommand @pythonArguments
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
