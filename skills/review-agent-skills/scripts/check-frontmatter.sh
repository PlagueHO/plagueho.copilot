#!/usr/bin/env bash
# Purpose: check explicit skill paths without executing their contents.
# Parameters: [--profile standard|catalog] -- PATH [PATH...]
# Usage: bash check-frontmatter.sh --profile catalog -- ./skills/example
set -euo pipefail
if ! command -v node >/dev/null 2>&1; then
    printf '%s\n' 'Node.js 20+ is required. No checks ran.' >&2
    exit 2
fi
SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_ROOT/check-frontmatter.mjs" "$@"
