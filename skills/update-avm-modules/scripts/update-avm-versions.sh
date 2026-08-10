#!/usr/bin/env bash
# Update-AvmVersions — Shell variant
#
# Applies version updates to AVM module references in Bicep files.
# Takes a JSON file or stdin containing an array of update operations.
#
# Each object must have:
#   Module, OldVersion, NewVersion, FilePath
#
# Usage:
#   ./update-avm-versions.sh --file updates.json
#   echo '<json>' | ./update-avm-versions.sh --stdin
#
# Requirements: jq, sed

set -euo pipefail

usage() {
    echo "Usage: $0 --file <updates.json> | --stdin" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

MODE=""
UPDATES_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        --file|-f)
            MODE="file"
            UPDATES_FILE="$2"
            shift 2
            ;;
        --stdin)
            MODE="stdin"
            shift
            ;;
        *)
            usage
            ;;
    esac
done

for cmd in jq sed; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required command '$cmd' not found." >&2
        exit 1
    fi
done

# Read updates JSON
if [ "$MODE" = "file" ]; then
    if [ ! -f "$UPDATES_FILE" ]; then
        echo "Error: File not found: $UPDATES_FILE" >&2
        exit 1
    fi
    updates_json=$(cat "$UPDATES_FILE")
elif [ "$MODE" = "stdin" ]; then
    updates_json=$(cat)
else
    usage
fi

count=$(echo "$updates_json" | jq 'length')
if [ "$count" -eq 0 ]; then
    echo "No updates to apply." >&2
    echo "[]"
    exit 0
fi

updated_count=0
skipped_count=0
failed_count=0
json_results="["

for ((i = 0; i < count; i++)); do
    module=$(echo "$updates_json" | jq -r ".[$i].Module")
    old_version=$(echo "$updates_json" | jq -r ".[$i].OldVersion")
    new_version=$(echo "$updates_json" | jq -r ".[$i].NewVersion")
    file_path=$(echo "$updates_json" | jq -r ".[$i].FilePath")

    status="FAILED"
    message=""

    if [ ! -f "$file_path" ]; then
        status="FAILED"
        message="File not found"
        failed_count=$((failed_count + 1))
    else
        search_pattern="br/public:${module}:${old_version}"
        replace_pattern="br/public:${module}:${new_version}"

        # Count occurrences
        occurrences=$(grep -cF "$search_pattern" "$file_path" || true)

        if [ "$occurrences" -eq 0 ]; then
            status="SKIPPED"
            message="Reference not found in file"
            skipped_count=$((skipped_count + 1))
        else
            # Escape special characters for sed
            escaped_search=$(printf '%s\n' "$search_pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')
            escaped_replace=$(printf '%s\n' "$replace_pattern" | sed 's/[[\.*^$()+?{|&]/\\&/g')

            sed -i "s|${escaped_search}|${escaped_replace}|g" "$file_path"
            status="UPDATED"
            message="Replaced $occurrences occurrence(s)"
            updated_count=$((updated_count + 1))
        fi
    fi

    [ "$i" -gt 0 ] && json_results="$json_results,"
    json_results="$json_results{\"Module\":\"$module\",\"OldVersion\":\"$old_version\",\"NewVersion\":\"$new_version\",\"FilePath\":\"$file_path\",\"Status\":\"$status\",\"Message\":\"$message\"}"
done

json_results="$json_results]"

echo "" >&2
echo "Update Results: $updated_count updated, $skipped_count skipped, $failed_count failed" >&2
echo "" >&2

echo "$json_results" | jq .
