---
name: research-output-scaffolding

description: >-
  **WORKFLOW SKILL** — Scaffold the .research/ output folder structure for a
  research topic, creating note directories per area, log files, and output
  section placeholders based on the research plan. WHEN: "scaffold research
  output", "create research folder", "initialize research directory",
  "set up research workspace", "research output structure",
  "scaffold .research folder". INVOKES: run_in_terminal for scaffolding
  scripts. FOR SINGLE OPERATIONS: Create directories manually.

metadata:
  author: PlagueHO
  version: "1.0"
  reference: https://github.com/PlagueHO/plagueho.copilot

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Provide the topic slug and purpose. E.g., "Scaffold output for
  azure-container-apps-dynamic-sessions as a deep-guide".

user-invocable: true
---

# Research Output Scaffolding

Scaffold the complete `.research/` folder structure for a research topic.
Creates all directories, initializes log files, and generates output section
placeholder files based on the research plan and purpose mapping.

## Prerequisites

- A confirmed research plan at `.research/<topic-slug>/plan.md`
- The research purpose (determines which output sections to scaffold)

## Process

### Step 1 — Load Configuration

Read the plan at `.research/<topic-slug>/plan.md` to determine:

- Topic slug (folder name)
- Purpose (output section template selection)
- Enabled research areas (note subdirectories)

Read [section-area-mapping.md](references/section-area-mapping.md) for output-section/note-area mappings.

Read [writing-guidelines.md](references/writing-guidelines.md) for output quality expectations.

### Step 2 — Create Directory Structure

Create the folder tree:

```text
.research/<topic-slug>/
├── plan.md                    # Already exists from plan skill
├── log.md                     # Research activity log
├── notes/
│   ├── docs/                  # Microsoft Learn documentation notes
│   ├── tech/                  # Technical documentation notes
│   ├── blogs/                 # Blog and article notes
│   ├── arch/                  # Architecture pattern notes
│   ├── samples/               # Code sample notes
│   ├── solutions/             # Solution accelerator notes
│   └── other/                 # Third-party and community notes
└── output/
    ├── 01-overview.md         # Output sections (from purpose mapping)
    ├── 02-architecture.md
    ├── ...
    └── README.md              # Combined output index
```

Only create `notes/` subdirectories for areas enabled in the plan.
Only create `output/` section files matching the purpose mapping.

### Step 3 — Initialize Log File

Create `.research/<topic-slug>/log.md`:

```markdown
# Research Log: {{TOPIC}}

Research started: {{DATE}}
Purpose: {{PURPOSE}}

## Activity Log

- [{{TIMESTAMP}}] SCAFFOLD: Output structure created
```

### Step 4 — Generate Section Placeholders

For each output section in the purpose mapping, create a placeholder file in `output/` using the section template:

```markdown
---
section: "{{SECTION_ID}}"
title: "{{SECTION_TITLE}}"
status: placeholder
primary_areas:
  - {{AREA_1}}
  - {{AREA_2}}
---

# {{SECTION_TITLE}}

> {{SECTION_DESCRIPTION}}

<!-- Content will be synthesized from notes in: {{PRIMARY_AREAS}} -->
<!-- Supporting content from: {{SECONDARY_AREAS}} -->
```

### Step 5 — Generate Output README

Create `.research/<topic-slug>/output/README.md` as a combined index
linking to all section files with their status.

### Step 6 — Run Scaffolding Script (optional)

For script-based scaffolding:

- **PowerShell**: `scripts/New-ResearchOutput.ps1 -TopicSlug <slug> -Purpose <purpose>`
- **Bash**: `scripts/new-research-output.sh <slug> <purpose>`

## Output

A scaffolded `.research/<topic-slug>/` directory ready for research agents to populate with notes and synthesize into output sections.
