#!/usr/bin/env bash
# Purpose: return stable MCR version comparisons as a JSON array.
# Parameters: FILE (legacy) | --file PATH | --directory PATH | --files PATH...
# Usage: bash get-avm-latest-versions.sh --directory infra
set -euo pipefail
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ $# -eq 1 && "$1" != --* ]]; then
    exec node "$SCRIPT_ROOT/avm.mjs" latest --file "$1"
fi
exec node "$SCRIPT_ROOT/avm.mjs" latest "$@"
