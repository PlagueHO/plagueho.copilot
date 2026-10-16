#!/usr/bin/env bash
# Purpose: apply approved updates with a complete rollback snapshot.
# Parameters: --file JSON | --stdin; --snapshot-file NEW_PATH is required.
# Usage: bash update-avm-versions.sh --file updates.json --snapshot-file snapshot.json
set -euo pipefail
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_ROOT/avm.mjs" update "$@"
