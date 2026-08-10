#!/usr/bin/env bash
#
# invoke-pester-validation.sh
#
# Validation gate for the upgrade-pester-v4-to-v5 skill. Confirms Pester 5 is
# installed, runs Invoke-Pester via pwsh with the advanced configuration object,
# and fails on test failures or Discovery errors.
#
# Usage:
#   ./invoke-pester-validation.sh [--path <dir-or-file>] [--verbosity <level>]
#
# Defaults: --path '.'  --verbosity 'Detailed'. Requires: pwsh, Pester 5.x.

set -euo pipefail

SCAN_PATH="."
VERBOSITY="Detailed"
MIN_VERSION="5.5.0"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            SCAN_PATH="$2"
            shift 2
            ;;
        --verbosity)
            VERBOSITY="$2"
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

if ! command -v pwsh >/dev/null 2>&1; then
    echo "pwsh (PowerShell 7+) is required but was not found." >&2
    exit 2
fi

pwsh -NoProfile -Command "
    \$ErrorActionPreference = 'Stop'
    \$pester = Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not \$pester -or \$pester.Version -lt [version]'$MIN_VERSION') {
        Write-Error 'Pester $MIN_VERSION+ is required. Install-Module Pester -MinimumVersion $MIN_VERSION -Force -SkipPublisherCheck'
        exit 2
    }
    Import-Module Pester -MinimumVersion '$MIN_VERSION' -Force
    \$config = New-PesterConfiguration
    \$config.Run.Path = '$SCAN_PATH'
    \$config.Run.PassThru = \$true
    \$config.Output.Verbosity = '$VERBOSITY'
    \$result = Invoke-Pester -Configuration \$config
    Write-Host ''
    Write-Host (\"Passed: {0}  Failed: {1}  Skipped: {2}  NotRun: {3}\" -f \$result.PassedCount, \$result.FailedCount, \$result.SkippedCount, \$result.NotRunCount)
    if (\$result.FailedCount -gt 0) {
        Write-Error \"Pester reported \$(\$result.FailedCount) failed test(s).\"
        exit 1
    }
    if (@(\$result.Containers | Where-Object { \$_.Result -eq 'Failed' -and \$_.Tests.Count -eq 0 }).Count -gt 0) {
        Write-Error 'A test container failed during Discovery (no tests ran). Complete the structural migration.'
        exit 1
    }
    Write-Host 'Validation passed: no failed tests and no Discovery errors.' -ForegroundColor Green
    exit 0
"
