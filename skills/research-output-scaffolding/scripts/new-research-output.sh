#!/usr/bin/env bash
# Scaffolds a .research/ output folder structure for a Microsoft technology research topic.
#
# Usage:
#   ./new-research-output.sh <topic-slug> <purpose>
#
# Parameters:
#   topic-slug  Kebab-case topic folder name (e.g., "azure-container-apps-dynamic-sessions")
#   purpose     Research purpose: deep-guide, presentation, lab, or demo
#
# Example:
#   ./new-research-output.sh azure-container-apps-dynamic-sessions deep-guide

set -euo pipefail

TOPIC_SLUG="${1:?Usage: $0 <topic-slug> <purpose>}"
PURPOSE="${2:?Usage: $0 <topic-slug> <purpose>}"

# Validate purpose
case "$PURPOSE" in
  deep-guide|presentation|lab|demo) ;;
  *) echo "Error: purpose must be one of: deep-guide, presentation, lab, demo" >&2; exit 1 ;;
esac

# Define research areas
AREAS=(docs tech blogs arch samples solutions other)

# Define output sections per purpose
declare -a SECTIONS
case "$PURPOSE" in
  deep-guide)
    SECTIONS=(01-overview 02-architecture 03-getting-started 04-configuration 05-security 06-operations 07-integration 08-samples 09-limitations)
    ;;
  presentation)
    SECTIONS=(01-hook 02-solution 03-architecture 04-demo-flow 05-deep-dive 06-comparison 07-resources)
    ;;
  lab)
    SECTIONS=(00-prerequisites 01-exercise 02-exercise 03-exercise 04-exercise cleanup)
    ;;
  demo)
    SECTIONS=(01-overview 02-architecture 03-setup 04-walkthrough 05-extend)
    ;;
esac

BASE_PATH=".research/${TOPIC_SLUG}"
NOTES_PATH="${BASE_PATH}/notes"
OUTPUT_PATH="${BASE_PATH}/output"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "Creating research structure at: ${BASE_PATH}"

# Create note area directories
for area in "${AREAS[@]}"; do
  mkdir -p "${NOTES_PATH}/${area}"
done

# Create output directory
mkdir -p "${OUTPUT_PATH}"

# Initialize log file
cat > "${BASE_PATH}/log.md" << EOF
# Research Log: ${TOPIC_SLUG}

Research started: ${TIMESTAMP}
Purpose: ${PURPOSE}

## Activity Log

- [${TIMESTAMP}] SCAFFOLD: Output structure created
EOF

# Create output section placeholders
for section in "${SECTIONS[@]}"; do
  # Convert section ID to title (remove number prefix, replace hyphens with spaces, title case)
  title=$(echo "${section}" | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

  cat > "${OUTPUT_PATH}/${section}.md" << EOF
---
section: "${section}"
title: "${title}"
status: placeholder
---

# ${title}

<!-- Content will be synthesized from research notes -->
EOF
done

# Create output README
{
  echo "# Research Output: ${TOPIC_SLUG}"
  echo ""
  echo "## Sections"
  echo ""
  for section in "${SECTIONS[@]}"; do
    title=$(echo "${section}" | sed 's/^[0-9]*-//' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    echo "- [${title}](./${section}.md) — placeholder"
  done
} > "${OUTPUT_PATH}/README.md"

echo "Research structure scaffolded successfully."
echo "  Notes: ${NOTES_PATH}"
echo "  Output: ${OUTPUT_PATH}"
echo "  Sections: ${#SECTIONS[@]}"
