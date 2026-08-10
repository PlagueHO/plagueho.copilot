#!/usr/bin/env bash
# Test-BicepBuild — Shell variant
#
# Validates Bicep files using az bicep build and reports pass/fail
# status for each file. Outputs structured JSON results.
#
# Usage:
#   ./test-bicep-build.sh --file <bicep-file>
#   ./test-bicep-build.sh --directory <directory>
#   ./test-bicep-build.sh --files <file1> <file2> ...
#
# Requirements: az CLI with Bicep extension, jq

set -euo pipefail

usage() {
    echo "Usage: $0 --file <bicep-file> | --directory <directory> | --files <file1> [file2] ..." >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

MODE=""
TARGET=""
FILE_LIST=()

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
        --files)
            MODE="files"
            shift
            while [ $# -gt 0 ] && [[ ! "$1" =~ ^-- ]]; do
                FILE_LIST+=("$1")
                shift
            done
            ;;
        *)
            usage
            ;;
    esac
done

# Verify az CLI is available
if ! command -v az &>/dev/null; then
    echo "Error: Azure CLI (az) is not installed or not in PATH." >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq is not installed or not in PATH." >&2
    exit 1
fi

# Collect files to validate
declare -a files=()

case "$MODE" in
    file)
        if [ ! -f "$TARGET" ]; then
            echo "Error: File not found: $TARGET" >&2
            exit 1
        fi
        files+=("$TARGET")
        ;;
    directory)
        if [ ! -d "$TARGET" ]; then
            echo "Error: Directory not found: $TARGET" >&2
            exit 1
        fi
        while IFS= read -r f; do
            files+=("$f")
        done < <(find "$TARGET" -name '*.bicep' -type f | sort)
        ;;
    files)
        for f in "${FILE_LIST[@]}"; do
            if [ -f "$f" ]; then
                files+=("$f")
            else
                echo "Warning: File not found, skipping: $f" >&2
            fi
        done
        ;;
    *)
        usage
        ;;
esac

if [ ${#files[@]} -eq 0 ]; then
    echo "No Bicep files to validate." >&2
    echo "[]"
    exit 0
fi

echo "Validating ${#files[@]} Bicep file(s)..." >&2
echo "" >&2

passed_count=0
failed_count=0
json_results="["
index=0

for file in "${files[@]}"; do
    output=""
    status="PASSED"
    message="Validation successful"

    if output=$(az bicep build --file "$file" 2>&1); then
        status="PASSED"
        message="Validation successful"
        echo "  PASS: $file" >&2
        passed_count=$((passed_count + 1))

        # Clean up generated ARM template
        arm_file="${file%.bicep}.json"
        [ -f "$arm_file" ] && rm -f "$arm_file"
    else
        status="FAILED"
        message=$(echo "$output" | tr '"' "'" | tr '\n' ' ')
        echo "  FAIL: $file" >&2
        echo "        $output" >&2
        failed_count=$((failed_count + 1))
    fi

    [ "$index" -gt 0 ] && json_results="$json_results,"
    json_results="$json_results{\"FilePath\":\"$file\",\"Status\":\"$status\",\"Message\":\"$message\"}"
    index=$((index + 1))
done

json_results="$json_results]"

echo "" >&2
echo "Validation Results: $passed_count passed, $failed_count failed" >&2
echo "" >&2

echo "$json_results" | jq .

if [ "$failed_count" -gt 0 ]; then
    exit 1
fi
