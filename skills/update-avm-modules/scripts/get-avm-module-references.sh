#!/usr/bin/env bash
# Purpose: extract active AVM declarations with the shared Node.js implementation.
# Parameters: --file PATH | --directory PATH | --files PATH...
# Usage: bash get-avm-module-references.sh --directory infra
set -euo pipefail
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_ROOT/avm.mjs" references "$@"
