<#
.SYNOPSIS
    Scaffolds a .research/ output folder structure for a Microsoft technology research topic.

.DESCRIPTION
    Creates the complete directory tree including note area folders, output section
    placeholders, log file, and README index based on the specified purpose.

.PARAMETER TopicSlug
    The kebab-case topic slug used as the folder name (e.g., "azure-container-apps-dynamic-sessions").

.PARAMETER Purpose
    The research purpose: deep-guide, presentation, lab, or demo.

.PARAMETER OutputPath
    Optional base path for the .research folder. Defaults to current directory.

.EXAMPLE
    .\New-ResearchOutput.ps1 -TopicSlug "azure-container-apps-dynamic-sessions" -Purpose "deep-guide"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]*[a-z0-9]$')]
    [string]$TopicSlug,

    [Parameter(Mandatory)]
    [ValidateSet('deep-guide', 'presentation', 'lab', 'demo')]
    [string]$Purpose,

    [Parameter()]
    [string]$OutputPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# Define area directories
$areas = @('docs', 'tech', 'blogs', 'arch', 'samples', 'solutions', 'other')

# Define output sections per purpose
$sections = @{
    'deep-guide'   = @(
        '01-overview', '02-architecture', '03-getting-started',
        '04-configuration', '05-security', '06-operations',
        '07-integration', '08-samples', '09-limitations'
    )
    'presentation' = @(
        '01-hook', '02-solution', '03-architecture',
        '04-demo-flow', '05-deep-dive', '06-comparison', '07-resources'
    )
    'lab'          = @(
        '00-prerequisites', '01-exercise', '02-exercise',
        '03-exercise', '04-exercise', 'cleanup'
    )
    'demo'         = @(
        '01-overview', '02-architecture', '03-setup',
        '04-walkthrough', '05-extend'
    )
}

$basePath = Join-Path $OutputPath ".research" $TopicSlug
$notesPath = Join-Path $basePath "notes"
$outputSectionsPath = Join-Path $basePath "output"

# Create base directories
Write-Host "Creating research structure at: $basePath"
New-Item -ItemType Directory -Path $basePath -Force | Out-Null

# Create notes subdirectories
foreach ($area in $areas) {
    New-Item -ItemType Directory -Path (Join-Path $notesPath $area) -Force | Out-Null
}

# Create output directory
New-Item -ItemType Directory -Path $outputSectionsPath -Force | Out-Null

# Initialize log file
$timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
$logContent = @"
# Research Log: $TopicSlug

Research started: $timestamp
Purpose: $Purpose

## Activity Log

- [$timestamp] SCAFFOLD: Output structure created
"@
Set-Content -Path (Join-Path $basePath "log.md") -Value $logContent -Encoding utf8

# Create output section placeholders
$purposeSections = $sections[$Purpose]
foreach ($section in $purposeSections) {
    $sectionTitle = ($section -replace '^\d+-', '') -replace '-', ' '
    $sectionTitle = (Get-Culture).TextInfo.ToTitleCase($sectionTitle)
    $sectionContent = @"
---
section: "$section"
title: "$sectionTitle"
status: placeholder
---

# $sectionTitle

<!-- Content will be synthesized from research notes -->
"@
    Set-Content -Path (Join-Path $outputSectionsPath "$section.md") -Value $sectionContent -Encoding utf8
}

# Create output README
$readmeLines = @("# Research Output: $TopicSlug", "", "## Sections", "")
foreach ($section in $purposeSections) {
    $sectionTitle = ($section -replace '^\d+-', '') -replace '-', ' '
    $sectionTitle = (Get-Culture).TextInfo.ToTitleCase($sectionTitle)
    $readmeLines += "- [$sectionTitle](./$section.md) — placeholder"
}
Set-Content -Path (Join-Path $outputSectionsPath "README.md") -Value ($readmeLines -join "`n") -Encoding utf8

Write-Host "Research structure scaffolded successfully."
Write-Host "  Notes: $notesPath"
Write-Host "  Output: $outputSectionsPath"
Write-Host "  Sections: $($purposeSections.Count)"
