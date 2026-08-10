#!/usr/bin/env bash
# update-marketplace-from-plugins.sh
#
# Compatibility wrapper for the shared Node.js marketplace generator.
#
# Usage:
#   ./scripts/update-marketplace-from-plugins.sh [repo-root]

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="${1:-$(cd "$script_dir/.." && pwd)}"
node "$repo_root/eng/generate-marketplace.mjs" "$repo_root"
