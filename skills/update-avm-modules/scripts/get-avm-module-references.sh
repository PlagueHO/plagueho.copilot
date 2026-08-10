#!/usr/bin/env bash
# Get-AvmModuleReferences — Shell variant
#
# Extracts Azure Verified Module (AVM) references from Bicep files
# and outputs structured JSON with module path, current version,
# file path, and line number.
#
# Usage:
#   ./get-avm-module-references.sh --file <bicep-file>
#   ./get-avm-module-references.sh --directory <directory>
#
# Requirements: grep, sed, jq

set -euo pipefail

usage() {
    echo "Usage: $0 --file <bicep-file> | --directory <directory>" >&2
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

MODE=""
TARGET=""

while [ $# -gt 0 ]; do
    case "$1" in
        --file|-f)
            MODE="file"
            TARGET="$2"
            shift 2
            ;;
        --directory|-d)
            MODE="directory"
            TARGET="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$MODE" ] || [ -z "$TARGET" ]; then
    usage
fi

for cmd in grep sed jq; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found." >&2
        exit 1
    fi
done

# Collect files to scan
if [ "$MODE" = "file" ]; then
    if [ ! -f "$TARGET" ]; then
        echo "Error: File not found: $TARGET" >&2
        exit 1
    fi
    FILES="$TARGET"
else
    if [ ! -d "$TARGET" ]; then
        echo "Error: Directory not found: $TARGET" >&2
        exit 1
    fi
    FILES=$(find "$TARGET" -name '*.bicep' -type f | sort)
    if [ -z "$FILES" ]; then
        echo "No Bicep files found." >&2
        echo "[]"
        exit 0
    fi
fi

json_results="["
count=0

while IFS= read -r file; do
    line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Extract all AVM module references from this line
        matches=$(echo "$line" | grep -oE 'br/public:(avm/(res|ptn|utl)/[^:]+):([0-9]+\.[0-9]+(\.[0-9]+)?)' || true)
        if [ -n "$matches" ]; then
            while IFS= read -r match; do
                module=$(echo "$match" | sed -E 's|br/public:(avm/[^:]+):.*|\1|')
                version=$(echo "$match" | sed -E 's|br/public:avm/[^:]+:([0-9]+\.[0-9]+(\.[0-9]+)?)|\1|')
                [ "$count" -gt 0 ] && json_results="$json_results,"
                json_results="$json_results{\"Module\":\"$module\",\"Version\":\"$version\",\"FilePath\":\"$file\",\"LineNumber\":$line_num}"
                count=$((count + 1))
            done <<<"$matches"
        fi
    done < "$file"
done <<<"$FILES"

json_results="$json_results]"

if [ "$count" -eq 0 ]; then
    echo "No AVM module references found." >&2
    echo "[]"
    exit 0
fi

file_count=$(echo "$FILES" | wc -l | tr -d ' ')
echo "Found $count AVM module reference(s) in $file_count file(s)." >&2
echo "$json_results" | jq .
