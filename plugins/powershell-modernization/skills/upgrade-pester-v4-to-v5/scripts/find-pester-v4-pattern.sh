#!/usr/bin/env bash
#
# find-pester-v4-pattern.sh
#
# Scans PowerShell Pester test files for Pester v4 constructs that must change
# for Pester v5. Reports every matching line as the migration worklist for the
# upgrade-pester-v4-to-v5 skill.
#
# Usage:
#   ./find-pester-v4-pattern.sh [--path <dir-or-file>]
#
# Defaults to the current directory. Requires: bash, grep, find.

set -euo pipefail

SCAN_PATH="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --path)
            SCAN_PATH="$2"
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

# Pattern label => extended-regex. Most impactful issues first.
declare -a LABELS=(
    "Legacy Should (no dash)"
    "Assert-MockCalled"
    "Assert-VerifiableMock(s)"
    "InModuleScope wrapper"
    "\$MyInvocation path discovery"
    "Invoke-Pester -Script"
    "Invoke-Pester -TestName"
    "Invoke-Pester -Show"
    "Invoke-Pester -PesterOption"
    "Invoke-Pester -Strict"
    "Pester v4 #Requires"
)
declare -a REGEXES=(
    'Should[[:space:]]+(Be|BeExactly|BeLike|Match|Throw|Contain|BeNullOrEmpty|BeOfType|BeGreaterThan|BeLessThan|Exist|HaveCount|BeIn|BeTrue|BeFalse)([[:space:]]|$)'
    'Assert-MockCalled'
    'Assert-VerifiableMocks?'
    '^[[:space:]]*InModuleScope'
    '\$MyInvocation\.MyCommand\.Path'
    '\-Script([[:space:]]|$)'
    '\-TestName([[:space:]]|$)'
    '\-Show([[:space:]]|$)'
    '\-PesterOption([[:space:]]|$)'
    '\-Strict([[:space:]]|$)'
    "ModuleVersion[[:space:]]*=[[:space:]]*'?4\."
)

# Collect files.
if [[ -f "$SCAN_PATH" ]]; then
    mapfile -t FILES < <(printf '%s\n' "$SCAN_PATH")
else
    mapfile -t FILES < <(find "$SCAN_PATH" -type f -name '*.Tests.ps1')
fi

total=0
for file in "${FILES[@]}"; do
    for i in "${!LABELS[@]}"; do
        # Exclude the dashed Should form when checking the legacy pattern.
        if [[ "${LABELS[$i]}" == "Legacy Should (no dash)" ]]; then
            matches=$(grep -nE "${REGEXES[$i]}" "$file" 2>/dev/null | grep -vE 'Should[[:space:]]+-' || true)
        else
            matches=$(grep -nE "${REGEXES[$i]}" "$file" 2>/dev/null || true)
        fi
        if [[ -n "$matches" ]]; then
            while IFS= read -r m; do
                ln="${m%%:*}"
                text="${m#*:}"
                printf '%s\t%s\t%s\t%s\n' "$file" "$ln" "${LABELS[$i]}" "$(echo "$text" | sed 's/^[[:space:]]*//')"
                total=$((total + 1))
            done <<< "$matches"
        fi
    done
done

if [[ "$total" -eq 0 ]]; then
    echo "No Pester v4 patterns detected."
else
    echo ""
    echo "Found $total v4 pattern match(es)."
fi
