<#
.SYNOPSIS
    Evaluates a .prompt.md file for skill suitability and converts it to an
    Agent Skill directory.

.DESCRIPTION
    Reads a GitHub Copilot prompt file (.prompt.md), evaluates whether it is
    suitable for conversion to an Agent Skill per agentskills.io criteria,
    and scaffolds the skill directory with a converted SKILL.md.

    The script performs suitability checks (step count, reusability,
    asset potential) and reports a recommendation before proceeding.

.PARAMETER PromptPath
    Path to the .prompt.md file to convert.

.PARAMETER OutputPath
    Parent directory where the skill folder will be created.
    Defaults to the current directory.

.PARAMETER Name
    Override the derived skill name. If not provided, the name is derived
    from the prompt filename.

.PARAMETER Author
    Optional author name for the metadata field.

.PARAMETER Version
    Optional version string for the metadata field. Defaults to "1.0".

.PARAMETER Force
    Skip suitability evaluation and convert regardless of assessment.

.EXAMPLE
    .\Convert-PromptToSkill.ps1 -PromptPath ".github/prompts/my-prompt.prompt.md" -OutputPath ".github/skills"

.EXAMPLE
    .\Convert-PromptToSkill.ps1 -PromptPath ".github/prompts/my-prompt.prompt.md" -Name "custom-name" -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PromptPath,

    [Parameter()]
    [string]$OutputPath = '.',

    [Parameter()]
    [string]$Name = '',

    [Parameter()]
    [string]$Author = '',

    [Parameter()]
    [string]$Version = '1.0',

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helpers

function Write-Pass {
    param([string]$Message)
    Write-Host "  PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "  FAIL: $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "  INFO: $Message" -ForegroundColor Cyan
}

#endregion

#region Validate input

if (-not (Test-Path -Path $PromptPath -PathType Leaf)) {
    Write-Error "Prompt file not found: $PromptPath"
    return
}

if ($PromptPath -notmatch '\.prompt\.md$') {
    Write-Error "File must be a .prompt.md file. Got: $PromptPath"
    return
}

#endregion

#region Parse prompt file

Write-Host "Reading prompt: $PromptPath" -ForegroundColor Cyan
$lines = Get-Content -Path $PromptPath -Encoding utf8

# Parse frontmatter
if ($lines[0] -ne '---') {
    Write-Error 'Prompt file must start with YAML frontmatter (---).'
    return
}

$endIndex = -1
for ($i = 1; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq '---') {
        $endIndex = $i
        break
    }
}

if ($endIndex -eq -1) {
    Write-Error 'YAML frontmatter not closed (missing closing ---).'
    return
}

$frontmatterText = ($lines[1..($endIndex - 1)]) -join "`n"
$bodyLines = $lines[($endIndex + 1)..($lines.Count - 1)]
$bodyText = $bodyLines -join "`n"

# Extract frontmatter fields
$descMatch = [regex]::Match($frontmatterText, '(?m)^description:\s*[''"]?(.+?)[''"]?\s*$')
$promptDesc = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { '' }

$toolsMatch = [regex]::Match($frontmatterText, '(?m)^tools:\s*\[(.+)\]')
$promptTools = if ($toolsMatch.Success) { $toolsMatch.Groups[1].Value.Trim() } else { '' }

$argHintMatch = [regex]::Match($frontmatterText, '(?m)^argument-hint:\s*[''"]?(.+?)[''"]?\s*$')
$promptArgHint = if ($argHintMatch.Success) { $argHintMatch.Groups[1].Value.Trim() } else { '' }

# Count steps in body
$stepCount = ([regex]::Matches($bodyText, '(?m)^#{1,3}\s+Step\s+\d')).Count
if ($stepCount -eq 0) {
    # Also count numbered heading patterns like "## 1.", "### 1."
    $stepCount = ([regex]::Matches($bodyText, '(?m)^#{2,3}\s+\d+[\.\)]')).Count
}
if ($stepCount -eq 0) {
    # Count ordered list items at top level as steps
    $stepCount = ([regex]::Matches($bodyText, '(?m)^\d+\.\s+')).Count
}

# Detect file/artifact production indicators
$producesFiles = $bodyText -match '(?i)(create|generate|write|scaffold|produce|output|template|file|directory)'

# Detect tool references
$hasToolRefs = $bodyText -match '#tool:' -or $promptTools.Length -gt 0

# Detect input variables
$hasInputVars = $bodyText -match '\$\{input:'

# Detect terminal/script commands
$hasCommands = $bodyText -match '(?i)(```(?:bash|powershell|shell|sh|ps1|cmd)|run_in_terminal|terminal)'

Write-Host ''

#endregion

#region Suitability evaluation

Write-Host 'Suitability Assessment:' -ForegroundColor White
Write-Host ''

$forCount = 0
$againstCount = 0

# FOR-1: Multi-step workflow (3+ steps)
$for1 = $stepCount -ge 3
if ($for1) { $forCount++; Write-Pass "FOR-1: Multi-step workflow ($stepCount steps detected)" }
else { Write-Info "FOR-1: Multi-step workflow — No ($stepCount steps detected)" }

# FOR-2: Reusable across projects (not heavily context-specific)
$contextSpecificPatterns = [regex]::Matches($bodyText, '\$\{(workspace|input|config)').Count
$for2 = $contextSpecificPatterns -lt 5
if ($for2) { $forCount++; Write-Pass "FOR-2: Reusable across projects" }
else { Write-Info "FOR-2: Reusable across projects — No (heavy context-specific variables)" }

# FOR-3: Produces or transforms files
$for3 = $producesFiles
if ($for3) { $forCount++; Write-Pass 'FOR-3: Produces or transforms files' }
else { Write-Info 'FOR-3: Produces or transforms files — No' }

# FOR-4: Benefits from bundled assets
$for4 = $hasCommands -or ($bodyLines.Count -gt 100)
if ($for4) { $forCount++; Write-Pass 'FOR-4: Benefits from bundled assets (scripts/commands detected or long body)' }
else { Write-Info 'FOR-4: Benefits from bundled assets — No' }

# FOR-5: Domain expertise
$for5 = $bodyLines.Count -gt 50
if ($for5) { $forCount++; Write-Pass "FOR-5: Domain expertise (substantial instructions: $($bodyLines.Count) lines)" }
else { Write-Info "FOR-5: Domain expertise — No (short prompt: $($bodyLines.Count) lines)" }

# FOR-6: Repeatable with variations
$for6 = $hasInputVars -or ($bodyText -match '(?i)(paramete|variation|option|configur)')
if ($for6) { $forCount++; Write-Pass 'FOR-6: Repeatable with variations' }
else { Write-Info 'FOR-6: Repeatable with variations — No' }

# FOR-7: Tool orchestration
$for7 = $hasToolRefs
if ($for7) { $forCount++; Write-Pass 'FOR-7: Tool orchestration' }
else { Write-Info 'FOR-7: Tool orchestration — No' }

# AGAINST-1: Simple single-action task
$against1 = $stepCount -lt 3 -and $bodyLines.Count -lt 30
if ($against1) { $againstCount++; Write-Fail 'AGAINST-1: Simple single-action task' }

# AGAINST-2: Context-specific
$against2 = $contextSpecificPatterns -ge 5
if ($against2) { $againstCount++; Write-Fail 'AGAINST-2: Context-specific (many context variables)' }

# AGAINST-3: Conversational or advisory
$against3 = -not $producesFiles -and ($bodyText -match '(?i)(recommend|suggest|advise|analyz|assess|evaluat|review)')
if ($against3) { $againstCount++; Write-Fail 'AGAINST-3: Conversational or advisory (no artifact production)' }

# AGAINST-4: Already well-served by a prompt
$against4 = $stepCount -le 2 -and -not $hasCommands -and -not $for4
if ($against4) { $againstCount++; Write-Fail 'AGAINST-4: Already well-served by a prompt' }

Write-Host ''
Write-Host "Score: $forCount FOR, $againstCount AGAINST" -ForegroundColor White

$recommendation = 'Convert'
if ($forCount -lt 3) {
    $recommendation = 'Keep as prompt'
} elseif ($againstCount -ge 1) {
    $recommendation = 'Borderline'
}

Write-Host "Recommendation: $recommendation" -ForegroundColor $(
    switch ($recommendation) {
        'Convert' { 'Green' }
        'Borderline' { 'Yellow' }
        'Keep as prompt' { 'Red' }
    }
)

if (-not $Force -and $recommendation -eq 'Keep as prompt') {
    Write-Host ''
    Write-Host 'The prompt does not meet the minimum criteria for conversion.' -ForegroundColor Yellow
    Write-Host 'Use -Force to convert anyway.' -ForegroundColor Yellow
    return
}

#endregion

#region Derive skill name

if (-not $Name) {
    # Derive from filename: remove .prompt.md, replace non-alphanumeric with hyphens
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension(
        [System.IO.Path]::GetFileNameWithoutExtension($PromptPath)
    )
    $Name = ($fileName -replace '[^a-z0-9-]', '-' -replace '--+', '-' -replace '^-|-$', '').ToLower()
}

# Validate name
if ($Name.Length -gt 64) {
    Write-Error "Derived name '$Name' exceeds 64 characters. Use -Name to provide a shorter name."
    return
}

if ($Name -notmatch '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$') {
    Write-Error "Derived name '$Name' is invalid. Use -Name to provide a valid name."
    return
}

if ($Name -match '--') {
    Write-Error "Derived name '$Name' contains consecutive hyphens. Use -Name to provide a valid name."
    return
}

Write-Host ''
Write-Host "Skill name: $Name" -ForegroundColor Cyan

#endregion

#region Create skill directory

$skillDir = Join-Path -Path $OutputPath -ChildPath $Name

if (Test-Path -Path $skillDir) {
    Write-Error "Directory '$skillDir' already exists. Remove it first or choose a different name."
    return
}

Write-Host "Creating skill directory: $skillDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

# Create scripts/ if commands were detected
if ($hasCommands) {
    $scriptsDir = Join-Path -Path $skillDir -ChildPath 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    Write-Host '  Created: scripts/' -ForegroundColor DarkGray
}

# Create references/ if body is long
if ($bodyLines.Count -gt 200) {
    $refsDir = Join-Path -Path $skillDir -ChildPath 'references'
    New-Item -ItemType Directory -Path $refsDir -Force | Out-Null

    $refContent = @"
# Reference

Detailed reference documentation for the **$Name** skill.

## Overview

<!-- Extracted reference material from the original prompt. -->
"@
    Set-Content -Path (Join-Path -Path $refsDir -ChildPath 'REFERENCE.md') -Value $refContent -Encoding utf8NoBOM
    Write-Host '  Created: references/REFERENCE.md' -ForegroundColor DarkGray
}

#endregion

#region Generate SKILL.md

$title = ($Name -replace '-', ' ') -replace '(^| )(.)', { $_.Value.ToUpper() }

# Build description
$skillDesc = if ($promptDesc) {
    "**WORKFLOW SKILL** — $promptDesc"
} else {
    "**WORKFLOW SKILL** — Converted from prompt. Update this description."
}

# Truncate to 1024 chars
if ($skillDesc.Length -gt 1024) {
    $skillDesc = $skillDesc.Substring(0, 1021) + '...'
}

$fm = [System.Text.StringBuilder]::new()
[void]$fm.AppendLine('---')
[void]$fm.AppendLine("name: $Name")
[void]$fm.AppendLine('')

if ($skillDesc.Length -gt 80) {
    [void]$fm.AppendLine('description: >-')
    $words = $skillDesc -split '\s+'
    $line = '  '
    foreach ($word in $words) {
        if (($line.Length + $word.Length + 1) -gt 80 -and $line.Trim().Length -gt 0) {
            [void]$fm.AppendLine($line.TrimEnd())
            $line = "  $word"
        } else {
            if ($line.Trim().Length -eq 0) { $line = "  $word" }
            else { $line += " $word" }
        }
    }
    if ($line.Trim().Length -gt 0) { [void]$fm.AppendLine($line.TrimEnd()) }
} else {
    [void]$fm.AppendLine("description: `"$($skillDesc -replace '"', '\"')`"")
}

if ($Author -or $Version) {
    [void]$fm.AppendLine('')
    [void]$fm.AppendLine('metadata:')
    if ($Author) { [void]$fm.AppendLine("  author: $Author") }
    [void]$fm.AppendLine("  version: `"$Version`"")
    [void]$fm.AppendLine("  converted-from: `"$([System.IO.Path]::GetFileName($PromptPath))`"")
    [void]$fm.AppendLine('  generated-by: convert-prompt-to-skill')
}

if ($promptArgHint) {
    [void]$fm.AppendLine('')
    [void]$fm.AppendLine("argument-hint: `"$($promptArgHint -replace '"', '\"')`"")
}

[void]$fm.AppendLine('')
[void]$fm.AppendLine('compatibility:')
[void]$fm.AppendLine('  - GitHub Copilot')
[void]$fm.AppendLine('  - GitHub Copilot CLI')
[void]$fm.AppendLine('  - VS Code')
[void]$fm.AppendLine('')
[void]$fm.AppendLine('user-invocable: true')
[void]$fm.AppendLine('---')

# Convert body: remove prompt-specific syntax
$convertedBody = $bodyText
# Replace #tool: references with plain text
$convertedBody = $convertedBody -replace '#tool:(\w+)', 'the $1 tool'
# Replace ${input:...} with placeholder descriptions
$convertedBody = $convertedBody -replace '\$\{input:(\w+):([^}]+)\}', '<$2>'
$convertedBody = $convertedBody -replace '\$\{input:(\w+)\}', '<$1>'

$skillBody = @"

# $title

<!-- Converted from: $([System.IO.Path]::GetFileName($PromptPath)) -->

$convertedBody
"@

$skillContent = $fm.ToString() + $skillBody
$skillPath = Join-Path -Path $skillDir -ChildPath 'SKILL.md'
Set-Content -Path $skillPath -Value $skillContent -Encoding utf8NoBOM
Write-Host '  Created: SKILL.md' -ForegroundColor DarkGray

#endregion

#region Summary

Write-Host ''
Write-Host "Skill '$Name' created successfully." -ForegroundColor Green
Write-Host ''
Write-Host 'Directory structure:' -ForegroundColor Cyan

$allItems = Get-ChildItem -Path $skillDir -Recurse
$tree = @("$Name/")
foreach ($item in $allItems) {
    $relative = $item.FullName.Substring($skillDir.Length + 1) -replace '\\', '/'
    $depth = ($relative -split '/').Count - 1
    $indent = '    ' * $depth
    $display = Split-Path -Leaf $item.FullName
    if ($item.PSIsContainer) { $display += '/' }
    $tree += "${indent}--- $display"
}
$tree | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }

Write-Host ''
Write-Host 'Suitability: ' -NoNewline
Write-Host $recommendation -ForegroundColor $(
    switch ($recommendation) {
        'Convert' { 'Green' }
        'Borderline' { 'Yellow' }
        'Keep as prompt' { 'Red' }
    }
)
Write-Host "FOR criteria met: $forCount / 7"
Write-Host "AGAINST criteria met: $againstCount / 4"
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Yellow
Write-Host '  1. Review and refine the generated SKILL.md' -ForegroundColor DarkGray
Write-Host '  2. Rewrite the description with trigger keywords' -ForegroundColor DarkGray
Write-Host '  3. Add cross-platform scripts if needed' -ForegroundColor DarkGray
Write-Host '  4. Validate with: npx skills-ref validate' $skillDir -ForegroundColor DarkGray

#endregion
