<#
.SYNOPSIS
    Scans PowerShell Pester test files for Pester v4 constructs that must change
    for Pester v5.

.DESCRIPTION
    Walks one or more paths for *.Tests.ps1 files and reports every line that
    matches a known Pester v4 pattern (legacy assertions, deprecated mock
    cmdlets, removed Invoke-Pester parameters, and discovery-unsafe code). Use
    the output as the migration worklist for the upgrade-pester-v4-to-v5 skill.

.PARAMETER Path
    One or more directories or files to scan. Defaults to the current directory.

.PARAMETER OutputFormat
    'Table' (default) for human-readable output, or 'Object' to emit objects for
    further processing in a pipeline.

.EXAMPLE
    ./Find-PesterV4Pattern.ps1 -Path . -OutputFormat Table

.EXAMPLE
    ./Find-PesterV4Pattern.ps1 -Path ./tests -OutputFormat Object | Where-Object Pattern -eq 'Assert-MockCalled'
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string[]] $Path = '.',

    [Parameter()]
    [ValidateSet('Table', 'Object')]
    [string] $OutputFormat = 'Table'
)

$ErrorActionPreference = 'Stop'

# Pattern name => regex. Ordered so the most impactful issues surface first.
$patterns = [ordered]@{
    'Legacy Should (no dash)'      = '\bShould\s+(?!-)(Be|BeExactly|BeLike|BeLikeExactly|Match|MatchExactly|Throw|Contain|ContainExactly|BeNullOrEmpty|BeOfType|BeGreaterThan|BeLessThan|Exist|HaveCount|BeIn|BeTrue|BeFalse)\b'
    'Assert-MockCalled'            = '\bAssert-MockCalled\b'
    'Assert-VerifiableMock(s)'     = '\bAssert-VerifiableMocks?\b'
    'InModuleScope wrapper'        = '^\s*InModuleScope\b'
    '$MyInvocation path discovery' = '\$MyInvocation\.MyCommand\.Path'
    'Invoke-Pester -Script'        = '-Script\b'
    'Invoke-Pester -TestName'      = '-TestName\b'
    'Invoke-Pester -Show'          = '-Show\b'
    'Invoke-Pester -PesterOption'  = '-PesterOption\b'
    'Invoke-Pester -Strict'        = '-Strict\b'
    'Pester v4 #Requires'          = "ModuleVersion\s*=\s*'?4\."
}

$files = foreach ($p in $Path) {
    if (Test-Path -LiteralPath $p -PathType Leaf) {
        Get-Item -LiteralPath $p
    }
    else {
        Get-ChildItem -LiteralPath $p -Recurse -Filter '*.Tests.ps1' -File
    }
}

$results = foreach ($file in $files) {
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
        $lineNumber++
        foreach ($name in $patterns.Keys) {
            if ($line -match $patterns[$name]) {
                [pscustomobject]@{
                    File    = $file.FullName
                    Line    = $lineNumber
                    Pattern = $name
                    Text    = $line.Trim()
                }
            }
        }
    }
}

if (-not $results) {
    Write-Host 'No Pester v4 patterns detected.' -ForegroundColor Green
    return
}

if ($OutputFormat -eq 'Object') {
    $results
}
else {
    $results |
        Sort-Object File, Line |
        Format-Table File, Line, Pattern, Text -AutoSize -Wrap

    Write-Host ''
    Write-Host ("Found {0} v4 pattern(s) across {1} file(s)." -f
        $results.Count, ($results.File | Sort-Object -Unique).Count) -ForegroundColor Yellow
}
