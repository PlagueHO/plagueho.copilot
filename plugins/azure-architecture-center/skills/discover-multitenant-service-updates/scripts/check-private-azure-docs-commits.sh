#!/usr/bin/env bash
# Queries path-scoped commit history in a private Azure documentation repository.
#
# Usage:
#   ./check-private-azure-docs-commits.sh --repository MicrosoftDocs/azure-docs-pr \
#     --section articles/app-service --since 2026-01-15

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
python3 "$script_dir/check-private-azure-docs-commits.py" "$@"
