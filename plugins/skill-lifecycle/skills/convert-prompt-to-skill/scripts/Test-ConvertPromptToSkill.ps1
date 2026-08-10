<#
.SYNOPSIS
    Tests the convert-prompt-to-skill scripts and validates sample conversions.

.DESCRIPTION
    Creates a temporary test prompt file, runs the conversion scripts, and
    validates the output against the agentskills.io specification.

.PARAMETER ScriptDir
    Path to the scripts directory containing the conversion scripts.
    Defaults to the directory containing this test script.

.PARAMETER SkipCleanup
    Do not remove the temporary test directory after the test.

.EXAMPLE
    .\Test-ConvertPromptToSkill.ps1
    .\Test-ConvertPromptToSkill.ps1 -SkipCleanup
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ScriptDir = $PSScriptRoot,

    [Parameter()]
    [switch]$SkipCleanup
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$errors = [System.Collections.Generic.List[string]]::new()
$passed = 0

function Add-Pass {
    param([string]$Message)
    $script:passed++
    Write-Host "  PASS: $Message" -ForegroundColor Green
}

function Add-Fail {
    param([string]$Message)
    $script:errors.Add($Message)
    Write-Host "  FAIL: $Message" -ForegroundColor Red
}

Write-Host 'Testing convert-prompt-to-skill' -ForegroundColor Cyan
Write-Host ''

#region Setup

$testDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "test-convert-prompt-$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Create a test prompt that should pass suitability
$goodPrompt = @'
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
'@
$goodPromptPath = Join-Path -Path $testDir -ChildPath 'generate-api-docs.prompt.md'
Set-Content -Path $goodPromptPath -Value $goodPrompt -Encoding utf8NoBOM

# Create a test prompt that should fail suitability
$simplePrompt = @'
---
description: 'Say hello'
---
# Hello

Say hello to the user.
'@
$simplePromptPath = Join-Path -Path $testDir -ChildPath 'say-hello.prompt.md'
Set-Content -Path $simplePromptPath -Value $simplePrompt -Encoding utf8NoBOM

$outputDir = Join-Path -Path $testDir -ChildPath 'output'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

#endregion

#region Test 1: Convert a suitable prompt

Write-Host 'Test 1: Convert a suitable prompt' -ForegroundColor White

$convertScript = Join-Path -Path $ScriptDir -ChildPath 'Convert-PromptToSkill.ps1'

if (-not (Test-Path -Path $convertScript)) {
    Add-Fail "Script not found: $convertScript"
} else {
    try {
        & $convertScript `
            -PromptPath $goodPromptPath `
            -OutputPath $outputDir `
            -Author 'test' `
            -Version '1.0'

        $skillDir = Join-Path -Path $outputDir -ChildPath 'generate-api-docs'
        $skillMd = Join-Path -Path $skillDir -ChildPath 'SKILL.md'

        if (Test-Path -Path $skillDir) {
            Add-Pass 'Skill directory created'
        } else {
            Add-Fail 'Skill directory not created'
        }

        if (Test-Path -Path $skillMd) {
            Add-Pass 'SKILL.md created'

            $content = Get-Content -Path $skillMd -Raw -Encoding utf8

            # Check frontmatter has name field
            if ($content -match '(?m)^name:\s*generate-api-docs') {
                Add-Pass 'name field matches directory name'
            } else {
                Add-Fail 'name field missing or incorrect'
            }

            # Check description is present
            if ($content -match '(?m)^description:') {
                Add-Pass 'description field present'
            } else {
                Add-Fail 'description field missing'
            }

            # Check no #tool: references remain
            if ($content -notmatch '#tool:') {
                Add-Pass 'No #tool: references remain'
            } else {
                Add-Fail '#tool: references still present in converted skill'
            }

            # Check no ${input:} references remain
            if ($content -notmatch '\$\{input:') {
                Add-Pass 'No ${input:} references remain'
            } else {
                Add-Fail '${input:} references still present in converted skill'
            }

            # Check no agent field
            if ($content -notmatch '(?m)^agent:') {
                Add-Pass 'No agent field in skill frontmatter'
            } else {
                Add-Fail 'agent field should not be in skill frontmatter'
            }

            # Check no tools field
            if ($content -notmatch '(?m)^tools:') {
                Add-Pass 'No tools field in skill frontmatter'
            } else {
                Add-Fail 'tools field should not be in skill frontmatter'
            }

            # Check metadata has generated-by
            if ($content -match 'generated-by:\s*convert-prompt-to-skill') {
                Add-Pass 'generated-by metadata present'
            } else {
                Add-Fail 'generated-by metadata missing'
            }

        } else {
            Add-Fail 'SKILL.md not created'
        }
    } catch {
        Add-Fail "Conversion failed: $_"
    }
}

#endregion

#region Test 2: Reject an unsuitable prompt

Write-Host ''
Write-Host 'Test 2: Reject an unsuitable prompt' -ForegroundColor White

$outputDir2 = Join-Path -Path $testDir -ChildPath 'output2'
New-Item -ItemType Directory -Path $outputDir2 -Force | Out-Null

if (-not (Test-Path -Path $convertScript)) {
    Add-Fail "Script not found: $convertScript"
} else {
    try {
        & $convertScript `
            -PromptPath $simplePromptPath `
            -OutputPath $outputDir2 `
            -Author 'test'
    } catch {
        # Expected to fail — rejection is verified below
    }

    $skillDir2 = Join-Path -Path $outputDir2 -ChildPath 'say-hello'
    if (-not (Test-Path -Path $skillDir2)) {
        Add-Pass 'Unsuitable prompt correctly rejected (no directory created)'
    } else {
        Add-Fail 'Unsuitable prompt should have been rejected but skill was created'
    }
}

#endregion

#region Test 3: Force convert an unsuitable prompt

Write-Host ''
Write-Host 'Test 3: Force convert an unsuitable prompt' -ForegroundColor White

$outputDir3 = Join-Path -Path $testDir -ChildPath 'output3'
New-Item -ItemType Directory -Path $outputDir3 -Force | Out-Null

if (-not (Test-Path -Path $convertScript)) {
    Add-Fail "Script not found: $convertScript"
} else {
    try {
        & $convertScript `
            -PromptPath $simplePromptPath `
            -OutputPath $outputDir3 `
            -Author 'test' `
            -Force

        $skillDir3 = Join-Path -Path $outputDir3 -ChildPath 'say-hello'
        if (Test-Path -Path $skillDir3) {
            Add-Pass 'Force flag allows conversion of unsuitable prompt'
        } else {
            Add-Fail 'Force flag did not create skill directory'
        }
    } catch {
        Add-Fail "Force conversion failed: $_"
    }
}

#endregion

#region Cleanup

if (-not $SkipCleanup) {
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ''
    Write-Host 'Cleaned up temporary test files.' -ForegroundColor DarkGray
}

#endregion

#region Results

Write-Host ''
Write-Host '---' -ForegroundColor White
Write-Host "Results: $passed passed, $($errors.Count) failed" -ForegroundColor $(
    if ($errors.Count -eq 0) { 'Green' } else { 'Red' }
)

if ($errors.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failures:' -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host "  - $err" -ForegroundColor Red
    }
    exit 1
}

#endregion
