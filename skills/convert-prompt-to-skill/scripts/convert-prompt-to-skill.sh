#!/usr/bin/env bash
# convert-prompt-to-skill.sh — Evaluate a .prompt.md file for skill suitability
# and convert it to an Agent Skill directory.
#
# Reads a GitHub Copilot prompt file, evaluates whether it is suitable for
# conversion to an Agent Skill per agentskills.io criteria, and scaffolds
# the skill directory with a converted SKILL.md.
#
# Usage:
#   ./convert-prompt-to-skill.sh --prompt-path <path> \
#       [--output-path <dir>] [--name <name>] [--author <author>] \
#       [--version <version>] [--force]

set -euo pipefail

# Defaults
PROMPT_PATH=""
OUTPUT_PATH="."
NAME=""
AUTHOR=""
VERSION="1.0"
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt-path)
            PROMPT_PATH="$2"; shift 2 ;;
        --output-path)
            OUTPUT_PATH="$2"; shift 2 ;;
        --name)
            NAME="$2"; shift 2 ;;
        --author)
            AUTHOR="$2"; shift 2 ;;
        --version)
            VERSION="$2"; shift 2 ;;
        --force)
            FORCE=true; shift ;;
        -h|--help)
            echo "Usage: $0 --prompt-path <path> [options]"
            echo ""
            echo "Options:"
            echo "  --prompt-path <path>   Path to the .prompt.md file (required)"
            echo "  --output-path <dir>    Parent directory for skill (default: current dir)"
            echo "  --name <name>          Override derived skill name"
            echo "  --author <author>      Author name for metadata"
            echo "  --version <version>    Version string (default: 1.0)"
            echo "  --force                Skip suitability evaluation"
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            exit 1
            ;;
    esac
done

# Validation
if [[ -z "$PROMPT_PATH" ]]; then
    echo "Error: --prompt-path is required." >&2
    exit 1
fi

if [[ ! -f "$PROMPT_PATH" ]]; then
    echo "Error: Prompt file not found: $PROMPT_PATH" >&2
    exit 1
fi

if [[ "$PROMPT_PATH" != *.prompt.md ]]; then
    echo "Error: File must be a .prompt.md file. Got: $PROMPT_PATH" >&2
    exit 1
fi

# Read file
echo -e "\033[36mReading prompt: ${PROMPT_PATH}\033[0m"
TOTAL_LINES=$(wc -l < "$PROMPT_PATH")

# Parse frontmatter
FIRST_LINE=$(head -n 1 "$PROMPT_PATH")
if [[ "$FIRST_LINE" != "---" ]]; then
    echo "Error: Prompt file must start with YAML frontmatter (---)." >&2
    exit 1
fi

END_LINE=$(tail -n +2 "$PROMPT_PATH" | grep -n '^---$' | head -n 1 | cut -d: -f1)
if [[ -z "$END_LINE" ]]; then
    echo "Error: YAML frontmatter not closed (missing closing ---)." >&2
    exit 1
fi

FRONTMATTER=$(sed -n "2,${END_LINE}p" "$PROMPT_PATH")
BODY_START=$((END_LINE + 2))
BODY=$(tail -n +"$BODY_START" "$PROMPT_PATH")
BODY_LINE_COUNT=$((TOTAL_LINES - END_LINE - 1))
if [[ $BODY_LINE_COUNT -lt 0 ]]; then
    BODY_LINE_COUNT=0
fi

# Extract frontmatter fields
PROMPT_DESC=$(echo "$FRONTMATTER" | grep -m1 '^description:' | sed "s/^description:\s*//" | sed "s/^['\"]//;s/['\"]$//" | xargs 2>/dev/null || echo "")
PROMPT_TOOLS=$(echo "$FRONTMATTER" | grep -m1 '^tools:' | sed "s/^tools:\s*//" || echo "")
PROMPT_ARG_HINT=$(echo "$FRONTMATTER" | grep -m1 '^argument-hint:' | sed "s/^argument-hint:\s*//" | sed "s/^['\"]//;s/['\"]$//" || echo "")

# Count steps in body
STEP_COUNT=$(echo "$BODY" | grep -cE '^#{1,3}\s+Step\s+[0-9]' || true)
if [[ $STEP_COUNT -eq 0 ]]; then
    STEP_COUNT=$(echo "$BODY" | grep -cE '^#{2,3}\s+[0-9]+[\.\)]' || true)
fi
if [[ $STEP_COUNT -eq 0 ]]; then
    STEP_COUNT=$(echo "$BODY" | grep -cE '^[0-9]+\.\s+' || true)
fi

# Detect indicators
PRODUCES_FILES=false
if echo "$BODY" | grep -qiE '(create|generate|write|scaffold|produce|output|template|file|directory)'; then
    PRODUCES_FILES=true
fi

HAS_TOOL_REFS=false
if echo "$BODY" | grep -q '#tool:' || [[ -n "$PROMPT_TOOLS" ]]; then
    HAS_TOOL_REFS=true
fi

HAS_INPUT_VARS=false
if echo "$BODY" | grep -q '\${input:'; then
    HAS_INPUT_VARS=true
fi

HAS_COMMANDS=false
if echo "$BODY" | grep -qiE '(```(bash|powershell|shell|sh|ps1|cmd)|run_in_terminal|terminal)'; then
    HAS_COMMANDS=true
fi

CONTEXT_SPECIFIC_COUNT=$(echo "$BODY" | grep -coE '\$\{(workspace|input|config)' || true)

echo ""

# Suitability evaluation
echo -e "\033[37mSuitability Assessment:\033[0m"
echo ""

FOR_COUNT=0
AGAINST_COUNT=0

# FOR-1: Multi-step workflow
if [[ $STEP_COUNT -ge 3 ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-1: Multi-step workflow (${STEP_COUNT} steps detected)"
else
    echo -e "  \033[36mINFO:\033[0m FOR-1: Multi-step workflow — No (${STEP_COUNT} steps detected)"
fi

# FOR-2: Reusable across projects
if [[ $CONTEXT_SPECIFIC_COUNT -lt 5 ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-2: Reusable across projects"
else
    echo -e "  \033[36mINFO:\033[0m FOR-2: Reusable across projects — No (heavy context-specific variables)"
fi

# FOR-3: Produces or transforms files
if [[ "$PRODUCES_FILES" == true ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-3: Produces or transforms files"
else
    echo -e "  \033[36mINFO:\033[0m FOR-3: Produces or transforms files — No"
fi

# FOR-4: Benefits from bundled assets
if [[ "$HAS_COMMANDS" == true ]] || [[ $BODY_LINE_COUNT -gt 100 ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-4: Benefits from bundled assets"
else
    echo -e "  \033[36mINFO:\033[0m FOR-4: Benefits from bundled assets — No"
fi

# FOR-5: Domain expertise
if [[ $BODY_LINE_COUNT -gt 50 ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-5: Domain expertise (${BODY_LINE_COUNT} lines)"
else
    echo -e "  \033[36mINFO:\033[0m FOR-5: Domain expertise — No (${BODY_LINE_COUNT} lines)"
fi

# FOR-6: Repeatable with variations
if [[ "$HAS_INPUT_VARS" == true ]] || echo "$BODY" | grep -qiE '(paramete|variation|option|configur)'; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-6: Repeatable with variations"
else
    echo -e "  \033[36mINFO:\033[0m FOR-6: Repeatable with variations — No"
fi

# FOR-7: Tool orchestration
if [[ "$HAS_TOOL_REFS" == true ]]; then
    ((FOR_COUNT++)) || true
    echo -e "  \033[32mPASS:\033[0m FOR-7: Tool orchestration"
else
    echo -e "  \033[36mINFO:\033[0m FOR-7: Tool orchestration — No"
fi

# AGAINST-1: Simple single-action task
if [[ $STEP_COUNT -lt 3 ]] && [[ $BODY_LINE_COUNT -lt 30 ]]; then
    ((AGAINST_COUNT++)) || true
    echo -e "  \033[31mFAIL:\033[0m AGAINST-1: Simple single-action task"
fi

# AGAINST-2: Context-specific
if [[ $CONTEXT_SPECIFIC_COUNT -ge 5 ]]; then
    ((AGAINST_COUNT++)) || true
    echo -e "  \033[31mFAIL:\033[0m AGAINST-2: Context-specific"
fi

# AGAINST-3: Conversational or advisory
if [[ "$PRODUCES_FILES" == false ]] && echo "$BODY" | grep -qiE '(recommend|suggest|advise|analyz|assess|evaluat|review)'; then
    ((AGAINST_COUNT++)) || true
    echo -e "  \033[31mFAIL:\033[0m AGAINST-3: Conversational or advisory"
fi

# AGAINST-4: Already well-served by a prompt
if [[ $STEP_COUNT -le 2 ]] && [[ "$HAS_COMMANDS" == false ]]; then
    ((AGAINST_COUNT++)) || true
    echo -e "  \033[31mFAIL:\033[0m AGAINST-4: Already well-served by a prompt"
fi

echo ""
echo -e "Score: ${FOR_COUNT} FOR, ${AGAINST_COUNT} AGAINST"

RECOMMENDATION="Convert"
if [[ $FOR_COUNT -lt 3 ]]; then
    RECOMMENDATION="Keep as prompt"
elif [[ $AGAINST_COUNT -ge 1 ]]; then
    RECOMMENDATION="Borderline"
fi

case "$RECOMMENDATION" in
    "Convert")
        echo -e "Recommendation: \033[32m${RECOMMENDATION}\033[0m" ;;
    "Borderline")
        echo -e "Recommendation: \033[33m${RECOMMENDATION}\033[0m" ;;
    "Keep as prompt")
        echo -e "Recommendation: \033[31m${RECOMMENDATION}\033[0m" ;;
esac

if [[ "$FORCE" != true ]] && [[ "$RECOMMENDATION" == "Keep as prompt" ]]; then
    echo ""
    echo -e "\033[33mThe prompt does not meet the minimum criteria for conversion.\033[0m"
    echo -e "\033[33mUse --force to convert anyway.\033[0m"
    exit 1
fi

# Derive skill name
if [[ -z "$NAME" ]]; then
    FILENAME=$(basename "$PROMPT_PATH" .prompt.md)
    NAME=$(echo "$FILENAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//')
fi

# Validate name
name_len=${#NAME}
if [[ $name_len -gt 64 ]]; then
    echo "Error: Derived name '${NAME}' exceeds 64 characters. Use --name." >&2
    exit 1
fi

if ! echo "$NAME" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
    echo "Error: Derived name '${NAME}' is invalid. Use --name." >&2
    exit 1
fi

if echo "$NAME" | grep -q -- '--'; then
    echo "Error: Derived name '${NAME}' contains consecutive hyphens. Use --name." >&2
    exit 1
fi

echo ""
echo -e "\033[36mSkill name: ${NAME}\033[0m"

# Create skill directory
SKILL_DIR="${OUTPUT_PATH}/${NAME}"

if [[ -d "$SKILL_DIR" ]]; then
    echo "Error: Directory '${SKILL_DIR}' already exists." >&2
    exit 1
fi

echo "Creating skill directory: ${SKILL_DIR}"
mkdir -p "$SKILL_DIR"

if [[ "$HAS_COMMANDS" == true ]]; then
    mkdir -p "${SKILL_DIR}/scripts"
    echo "  Created: scripts/"
fi

if [[ $BODY_LINE_COUNT -gt 200 ]]; then
    mkdir -p "${SKILL_DIR}/references"
    cat > "${SKILL_DIR}/references/REFERENCE.md" << REFEOF
# Reference

Detailed reference documentation for the **${NAME}** skill.

## Overview

<!-- Extracted reference material from the original prompt. -->
REFEOF
    echo "  Created: references/REFERENCE.md"
fi

# Generate SKILL.md
SKILL_FILE="${SKILL_DIR}/SKILL.md"
TITLE=$(echo "$NAME" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

# Build description
if [[ -n "$PROMPT_DESC" ]]; then
    SKILL_DESC="**WORKFLOW SKILL** — ${PROMPT_DESC}"
else
    SKILL_DESC="**WORKFLOW SKILL** — Converted from prompt. Update this description."
fi

# Truncate to 1024 chars
if [[ ${#SKILL_DESC} -gt 1024 ]]; then
    SKILL_DESC="${SKILL_DESC:0:1021}..."
fi

# Convert body: remove prompt-specific syntax
CONVERTED_BODY=$(echo "$BODY" | sed 's/#tool:\([a-zA-Z_]*\)/the \1 tool/g')
CONVERTED_BODY=$(echo "$CONVERTED_BODY" | sed 's/\${input:\([a-zA-Z_]*\):\([^}]*\)}/<\2>/g')
CONVERTED_BODY=$(echo "$CONVERTED_BODY" | sed 's/\${input:\([a-zA-Z_]*\)}/<\1>/g')

PROMPT_FILENAME=$(basename "$PROMPT_PATH")

{
    echo "---"
    echo "name: ${NAME}"
    echo ""

    desc_len=${#SKILL_DESC}
    if [[ $desc_len -gt 80 ]]; then
        echo "description: >-"
        echo "  ${SKILL_DESC}" | fold -s -w 78 | sed 's/^/  /' | sed '1s/^    //'
    else
        escaped_desc=$(echo "$SKILL_DESC" | sed 's/"/\\"/g')
        echo "description: \"${escaped_desc}\""
    fi

    if [[ -n "$AUTHOR" || -n "$VERSION" ]]; then
        echo ""
        echo "metadata:"
        if [[ -n "$AUTHOR" ]]; then
            echo "  author: ${AUTHOR}"
        fi
        echo "  version: \"${VERSION}\""
        echo "  converted-from: \"${PROMPT_FILENAME}\""
        echo "  generated-by: convert-prompt-to-skill"
    fi

    if [[ -n "$PROMPT_ARG_HINT" ]]; then
        echo ""
        escaped_hint=$(echo "$PROMPT_ARG_HINT" | sed 's/"/\\"/g')
        echo "argument-hint: \"${escaped_hint}\""
    fi

    echo ""
    echo "compatibility:"
    echo "  - GitHub Copilot"
    echo "  - GitHub Copilot CLI"
    echo "  - VS Code"
    echo ""
    echo "user-invocable: true"
    echo "---"
    echo ""
    echo "# ${TITLE}"
    echo ""
    echo "<!-- Converted from: ${PROMPT_FILENAME} -->"
    echo ""
    echo "${CONVERTED_BODY}"

} > "$SKILL_FILE"

echo "  Created: SKILL.md"

# Summary
echo ""
echo -e "\033[32mSkill '${NAME}' created successfully.\033[0m"
echo ""
echo -e "\033[36mDirectory structure:\033[0m"
echo "  ${NAME}/"
find "$SKILL_DIR" -mindepth 1 | sort | while IFS= read -r item; do
    relative="${item#"${SKILL_DIR}/"}"
    depth=$(echo "$relative" | tr -cd '/' | wc -c)
    indent=""
    for ((i = 0; i < depth; i++)); do indent="    ${indent}"; done
    base=$(basename "$item")
    if [[ -d "$item" ]]; then base="${base}/"; fi
    echo "  ${indent}--- ${base}"
done

echo ""
echo -e "Suitability: ${RECOMMENDATION}"
echo "FOR criteria met: ${FOR_COUNT} / 7"
echo "AGAINST criteria met: ${AGAINST_COUNT} / 4"
echo ""
echo -e "\033[33mNext steps:\033[0m"
echo "  1. Review and refine the generated SKILL.md"
echo "  2. Rewrite the description with trigger keywords"
echo "  3. Add cross-platform scripts if needed"
echo "  4. Validate with: npx skills-ref validate ${SKILL_DIR}"
