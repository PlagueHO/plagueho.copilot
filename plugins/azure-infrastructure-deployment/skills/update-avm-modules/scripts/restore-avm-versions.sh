#!/usr/bin/env bash
# Purpose: restore a complete AVM update batch without overwriting later edits.
# Parameters: --snapshot-file PATH
# Usage: bash restore-avm-versions.sh --snapshot-file snapshot.json
set -euo pipefail
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_ROOT/avm.mjs" restore "$@"
