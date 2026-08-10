<#
.SYNOPSIS
    Runs a Pester 5 test suite and fails on test failures or Discovery errors.

.DESCRIPTION
    Validation gate for the upgrade-pester-v4-to-v5 skill. Confirms Pester 5 is
    installed, runs Invoke-Pester with the advanced configuration object, and
    returns a non-zero exit code if any test failed or if Discovery produced
    errors (the signal that structural migration is incomplete).

.PARAMETER Path
    Path to the tests directory or a specific *.Tests.ps1 file. Defaults to the
    current directory.

.PARAMETER Verbosity
    Output verbosity: None, Normal, Detailed (default), or Diagnostic.

.PARAMETER MinimumPesterVersion
    Minimum required Pester version. Defaults to 5.5.0.

.EXAMPLE
    ./Invoke-PesterValidation.ps1 -Path ./tests -Verbosity Detailed
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $Path = '.',

    [Parameter()]
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string] $Verbosity = 'Detailed',

    [Parameter()]
    [version] $MinimumPesterVersion = '5.5.0'
)

$ErrorActionPreference = 'Stop'

$pester = Get-Module Pester -ListAvailable |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pester -or $pester.Version -lt $MinimumPesterVersion) {
    Write-Error (("Pester {0}+ is required. Install it with: " +
        "Install-Module Pester -MinimumVersion {0} -Force -SkipPublisherCheck") -f $MinimumPesterVersion)
    exit 2
}

Import-Module Pester -MinimumVersion $MinimumPesterVersion -Force

$config = New-PesterConfiguration
$config.Run.Path = $Path
$config.Run.PassThru = $true
$config.Output.Verbosity = $Verbosity

$result = Invoke-Pester -Configuration $config

Write-Host ''
Write-Host ("Passed: {0}  Failed: {1}  Skipped: {2}  NotRun: {3}" -f
    $result.PassedCount, $result.FailedCount, $result.SkippedCount, $result.NotRunCount)

# Surface Discovery errors explicitly — these mean Step 3 structural migration
# is not yet complete.
if ($result.FailedCount -gt 0) {
    Write-Error "Pester reported $($result.FailedCount) failed test(s)."
    exit 1
}

if (@($result.Containers | Where-Object { $_.Result -eq 'Failed' -and $_.Tests.Count -eq 0 }).Count -gt 0) {
    Write-Error 'A test container failed during Discovery (no tests ran). Complete the structural migration.'
    exit 1
}

Write-Host 'Validation passed: no failed tests and no Discovery errors.' -ForegroundColor Green
exit 0
