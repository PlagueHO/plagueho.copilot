#!/usr/bin/env bash
# test-convert-prompt-to-skill.sh — Test the conversion scripts and validate output.
#
# Creates temporary test prompts, runs conversions, and checks results.
#
# Usage:
#   ./test-convert-prompt-to-skill.sh [--skip-cleanup]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKIP_CLEANUP=false

if [[ "${1:-}" == "--skip-cleanup" ]]; then
    SKIP_CLEANUP=true
fi

ERRORS=0
PASSED=0

pass() {
    ((PASSED++)) || true
    echo -e "  \033[32mPASS:\033[0m $1"
}

fail() {
    ((ERRORS++)) || true
    echo -e "  \033[31mFAIL:\033[0m $1"
}

echo -e "\033[36mTesting convert-prompt-to-skill\033[0m"
echo ""

# Setup
TEST_DIR=$(mktemp -d)

# Create a suitable test prompt
cat > "${TEST_DIR}/generate-api-docs.prompt.md" << 'PROMPTEOF'
---
agent: 'agent'
description: 'Generate structured API documentation from source code annotations.'
argument-hint: 'Provide the path to the source directory'
tools: [read/readFile, execute/runInTerminal, search]
---
# Generate API Documentation

Create comprehensive API docs from code annotations.

## Input

- **Source directory**: `${input:sourceDir:Path to source code}`

## Step 1: Scan Source Files

1. Scan the source directory for annotated files.
2. Use `#tool:search` to find doc-comment patterns.

## Step 2: Extract Annotations

1. Parse JSDoc, XML doc comments, or docstrings.
2. Build a structured model of each endpoint.

## Step 3: Generate Documentation

1. Create markdown files for each API endpoint.
2. Include request/response examples.
3. Generate a table of contents.

## Step 4: Validate Output

1. Run a link checker on generated docs.
2. Verify all endpoints are documented.

## Edge Cases

- Handle mixed annotation styles
- Skip files without annotations
PROMPTEOF

# Create an unsuitable test prompt
cat > "${TEST_DIR}/say-hello.prompt.md" << 'PROMPTEOF'
---
description: 'Say hello'
---
# Hello

Say hello to the user.
PROMPTEOF

OUTPUT_DIR="${TEST_DIR}/output"
mkdir -p "$OUTPUT_DIR"

CONVERT_SCRIPT="${SCRIPT_DIR}/convert-prompt-to-skill.sh"

# Test 1: Convert a suitable prompt
echo -e "\033[37mTest 1: Convert a suitable prompt\033[0m"

if [[ ! -f "$CONVERT_SCRIPT" ]]; then
    fail "Script not found: ${CONVERT_SCRIPT}"
else
    if bash "$CONVERT_SCRIPT" \
        --prompt-path "${TEST_DIR}/generate-api-docs.prompt.md" \
        --output-path "$OUTPUT_DIR" \
        --author "test" \
        --version "1.0"; then

        SKILL_DIR="${OUTPUT_DIR}/generate-api-docs"
        SKILL_MD="${SKILL_DIR}/SKILL.md"

        if [[ -d "$SKILL_DIR" ]]; then
            pass "Skill directory created"
        else
            fail "Skill directory not created"
        fi

        if [[ -f "$SKILL_MD" ]]; then
            pass "SKILL.md created"

            CONTENT=$(cat "$SKILL_MD")

            if echo "$CONTENT" | grep -q '^name: generate-api-docs'; then
                pass "name field matches directory name"
            else
                fail "name field missing or incorrect"
            fi

            if echo "$CONTENT" | grep -q '^description:'; then
                pass "description field present"
            else
                fail "description field missing"
            fi

            if ! echo "$CONTENT" | grep -q '#tool:'; then
                pass "No #tool: references remain"
            else
                fail "#tool: references still present"
            fi

            if ! echo "$CONTENT" | grep -q '\${input:'; then
                pass 'No ${input:} references remain'
            else
                fail '${input:} references still present'
            fi

            if ! echo "$CONTENT" | grep -q '^agent:'; then
                pass "No agent field in skill frontmatter"
            else
                fail "agent field should not be in skill frontmatter"
            fi

            if ! echo "$CONTENT" | grep -q '^tools:'; then
                pass "No tools field in skill frontmatter"
            else
                fail "tools field should not be in skill frontmatter"
            fi

            if echo "$CONTENT" | grep -q 'generated-by: convert-prompt-to-skill'; then
                pass "generated-by metadata present"
            else
                fail "generated-by metadata missing"
            fi
        else
            fail "SKILL.md not created"
        fi
    else
        fail "Conversion failed"
    fi
fi

# Test 2: Reject an unsuitable prompt
echo ""
echo -e "\033[37mTest 2: Reject an unsuitable prompt\033[0m"

OUTPUT_DIR2="${TEST_DIR}/output2"
mkdir -p "$OUTPUT_DIR2"

if [[ ! -f "$CONVERT_SCRIPT" ]]; then
    fail "Script not found"
else
    if bash "$CONVERT_SCRIPT" \
        --prompt-path "${TEST_DIR}/say-hello.prompt.md" \
        --output-path "$OUTPUT_DIR2" \
        --author "test" 2>/dev/null; then
        # Should have failed
        SKILL_DIR2="${OUTPUT_DIR2}/say-hello"
        if [[ -d "$SKILL_DIR2" ]]; then
            fail "Unsuitable prompt should have been rejected"
        else
            pass "Unsuitable prompt correctly rejected"
        fi
    else
        pass "Unsuitable prompt correctly rejected (exit code non-zero)"
    fi
fi

# Test 3: Force convert an unsuitable prompt
echo ""
echo -e "\033[37mTest 3: Force convert an unsuitable prompt\033[0m"

OUTPUT_DIR3="${TEST_DIR}/output3"
mkdir -p "$OUTPUT_DIR3"

if [[ ! -f "$CONVERT_SCRIPT" ]]; then
    fail "Script not found"
else
    if bash "$CONVERT_SCRIPT" \
        --prompt-path "${TEST_DIR}/say-hello.prompt.md" \
        --output-path "$OUTPUT_DIR3" \
        --author "test" \
        --force; then

        SKILL_DIR3="${OUTPUT_DIR3}/say-hello"
        if [[ -d "$SKILL_DIR3" ]]; then
            pass "Force flag allows conversion of unsuitable prompt"
        else
            fail "Force flag did not create skill directory"
        fi
    else
        fail "Force conversion failed"
    fi
fi

# Cleanup
if [[ "$SKIP_CLEANUP" != true ]]; then
    rm -rf "$TEST_DIR"
    echo ""
    echo "Cleaned up temporary test files."
fi

# Results
echo ""
echo "---"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "\033[32mResults: ${PASSED} passed, ${ERRORS} failed\033[0m"
else
    echo -e "\033[31mResults: ${PASSED} passed, ${ERRORS} failed\033[0m"
    exit 1
fi
