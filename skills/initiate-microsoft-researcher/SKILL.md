---
name: initiate-microsoft-researcher

description: >-
  **WORKFLOW SKILL** — Mandatory entry point for all research projects.
  Validates topic, confirms the plan with the user, scaffolds the folder
  structure, and initializes the research log before any subagent work
  begins. This skill is ONLY invoked by the research-microsoft-technology
  orchestrator agent. INVOKES: create-microsoft-research-plan,
  research-output-scaffolding, vscode_askQuestions. FOR SINGLE OPERATIONS:
  Not applicable — this skill must always be used to start research.

metadata:
  author: PlagueHO
  version: "1.0"
  reference: https://github.com/PlagueHO/plagueho.copilot

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Provide the Microsoft technology topic, purpose
  (deep-guide/presentation/lab/demo), and any source URLs. E.g., "Research
  Azure Container Apps dynamic sessions for a deep-guide".

user-invocable: false
context: fork
---

# Initiate Microsoft Researcher

Mandatory entry point for all research orchestration, called exclusively by
the `research-microsoft-technology` orchestrator agent. This skill ensures
the research plan is created, explicitly confirmed by the user, and the folder
structure is scaffolded before any research subagents are dispatched.

**This skill is the ONLY way to begin a research project. No exceptions.**

## Why This Exists

Without a formal initiation gate, the orchestrator agent may bypass the
structured workflow — fetching sources directly, writing notes inline, or
skipping subagent coordination entirely. This skill enforces the contract
between the orchestrator and the user.

## Prerequisites

- A clear technology topic from the user
- A defined purpose (`deep-guide`, `presentation`, `lab`, or `demo`)

## Process

### Step 1 — Collect Topic and Purpose

If the user has not provided both a topic and purpose, use
`vscode_askQuestions` to collect:

1. **Topic**: The Microsoft technology, feature, architecture, or solution
2. **Purpose**: What the research is for (`deep-guide`, `presentation`,
   `lab`, or `demo`)
3. **Source URLs** (optional): Any specific URLs the user wants included in
   the research
4. **Additional context** (optional): Audience, event name, constraints,
   deadlines, or special requirements

Derive the kebab-case topic slug from the topic name.

### Step 2 — Generate the Research Plan

Invoke the `create-microsoft-research-plan` skill with:

- Topic and topic slug
- Purpose
- Any user-provided source URLs (to include in the plan's search terms)
- Additional context

This produces `.research/<topic-slug>/plan.md`.

### Step 3 — Present Plan for User Confirmation (BLOCKING)

**This step is a hard gate. Research CANNOT proceed without explicit user
approval.**

Present the plan to the user showing:

1. Topic slug and folder path
2. Purpose and target audience
3. Enabled research areas with search terms
4. Expected output sections
5. Estimated source count targets per area
6. Any user-provided source URLs included

Use `vscode_askQuestions` with the following options:

- **Approve**: Plan is correct, proceed to scaffolding
- **Revise**: User provides feedback, return to Step 2 with adjustments
- **Cancel**: Abort the research project entirely

**If the user selects "Revise"**: Apply their feedback, regenerate the plan,
and present again. Repeat until approved or cancelled.

**If the user selects "Cancel"**: Stop immediately. Do not scaffold or
dispatch subagents.

**If the user selects "Approve"**: Proceed to Step 4.

### Step 4 — Scaffold the Folder Structure

Invoke the `research-output-scaffolding` skill with:

- Topic slug
- Purpose
- Enabled areas from the approved plan

This creates the full `.research/<topic-slug>/` directory tree including
`notes/`, `output/`, `log.md`, and section placeholders.

### Step 5 — Initialize the Research Log

Verify the log file exists at `.research/<topic-slug>/log.md` and append
the initiation entry:

```markdown
- [{{TIMESTAMP}}] INITIATE: Research project started
  - Topic: {{TOPIC}}
  - Purpose: {{PURPOSE}}
  - Plan: APPROVED by user
  - Areas: {{ENABLED_AREAS}}
  - Output sections: {{SECTION_COUNT}}
  - User-provided sources: {{SOURCE_COUNT}} URLs
```

### Step 6 — Create Initiation Marker

Create `.research/<topic-slug>/.initiated` with:

```yaml
initiated: true
approved_by: user
approved_at: {{TIMESTAMP}}
topic: {{TOPIC}}
purpose: {{PURPOSE}}
plan_hash: {{MD5_OF_PLAN}}
```

This marker file is checked by the orchestrator agent to verify that
initiation was completed before dispatching subagents.

### Step 7 — Return Control to Orchestrator

Return a structured summary to the orchestrator:

```markdown
## Research Project Initiated

- **Topic**: {{TOPIC}}
- **Slug**: {{TOPIC_SLUG}}
- **Purpose**: {{PURPOSE}}
- **Plan**: Approved ✅
- **Folder**: `.research/{{TOPIC_SLUG}}/`
- **Areas**: {{ENABLED_AREAS}}
- **Output sections**: {{SECTION_IDS}}
- **Ready for**: Phase 2 — Source Discovery

The orchestrator MUST now dispatch `research-source-discovery` as a
subagent. Do NOT fetch sources directly. Do NOT write notes directly.
Do NOT skip any phase.
```

## Constraints

- **NEVER** skip user confirmation — the plan must be explicitly approved
- **NEVER** proceed to source discovery or deep reading from this skill
- **NEVER** fetch source content — that is the deep-reader's responsibility
- **NEVER** write research notes — that is the deep-reader's responsibility
- **NEVER** synthesize content — that is the content-writer's responsibility
- This skill only creates the plan, confirms it, and scaffolds the structure
- If `vscode_askQuestions` is unavailable, present the plan in chat and ask
  for explicit textual confirmation before proceeding
