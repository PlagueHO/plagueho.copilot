#!/usr/bin/env bash
# Purpose: compile Bicep without modifying adjacent ARM templates.
# Parameters: --file PATH | --directory PATH | --files PATH...
# Usage: bash test-bicep-build.sh --file infra/main.bicep
set -euo pipefail
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_ROOT/avm.mjs" build "$@"
