---
name: create-microsoft-research-plan

description: >-
  **WORKFLOW SKILL** — Generate a structured research plan for a Microsoft
  technology topic, defining scope, research areas, search terms, and output
  section mapping based on purpose (guide/presentation/lab/demo). WHEN:
  "create research plan", "plan Microsoft research", "research plan for",
  "plan technical research", "scope research topic", "define research areas".
  INVOKES: editFiles. FOR SINGLE OPERATIONS: Create plan.md manually.

metadata:
  author: PlagueHO
  version: "1.0"
  reference: https://github.com/PlagueHO/plagueho.copilot

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Provide the Microsoft technology topic and purpose (deep-guide,
  presentation, lab, or demo). E.g., "Azure Container Apps dynamic
  sessions for a deep technical guide".

user-invocable: true
---

# Create Microsoft Research Plan

Generate a structured research plan for deep technical research on a
Microsoft technology feature, architecture, or solution. The plan defines
scope, research areas to investigate, search terms per area, and maps
output sections based on the research purpose.

## Prerequisites

- A clear technology topic (e.g., "Azure Container Apps dynamic sessions")
- A defined purpose: `deep-guide`, `presentation`, `lab`, or `demo`

## Process

### Step 1 — Confirm Topic and Purpose

If the user has not specified both a topic and purpose, ask:

1. **Topic**: Which Microsoft technology, feature, architecture, or solution?
2. **Purpose**: What is the research for?
   - `deep-guide` — comprehensive technical reference
   - `presentation` — tech talk or demo deck
   - `lab` — hands-on workshop exercises
   - `demo` — sample solution or proof-of-concept

Derive a kebab-case topic slug for the folder name (e.g.,
`azure-container-apps-dynamic-sessions`).

### Step 2 — Load Taxonomy and Purpose Mapping

Read [taxonomy.md](references/taxonomy.md) to understand all available
research dimensions.

Read [purpose-mapping.yaml](assets/purpose-mapping.yaml) to determine which
dimensions and output sections apply for the chosen purpose.

### Step 3 — Generate Search Terms

For each research area enabled by the purpose mapping, generate specific
search terms based on the topic:

| Area | Search Term Pattern |
|------|-------------------|
| `docs` | `"<topic> overview"`, `"<topic> documentation"`, `"<topic> concepts"` |
| `tech` | `"<topic> SDK"`, `"<topic> API reference"`, `"<topic> configuration"` |
| `blogs` | `"<topic> announcement"`, `"<topic> what's new"`, `"<topic> preview"` |
| `arch` | `"<topic> architecture"`, `"<topic> best practices"`, `"<topic> patterns"` |
| `samples` | `"<topic> sample"`, `"<topic> quickstart"`, `"<topic> tutorial"` |
| `solutions` | `"<topic> solution accelerator"`, `"<topic> reference implementation"` |
| `other` | `"<topic> community"`, `"<topic> comparison"`, `"<topic> real-world"` |

Use service-specific terminology.

### Step 4 — Write plan.md

Write the plan to `.research/<topic-slug>/plan.md` using the template at
[plan-template.md](assets/plan-template.md).

Fill in all sections:

- Topic and boundaries
- Purpose and target audience
- Research areas enabled (with search terms per area)
- Expected output sections (from purpose mapping)
- Estimated source count targets per area

### Step 5 — Present Plan for Confirmation

Show the user:

1. Topic slug and folder path
2. Purpose and enabled dimensions
3. Research areas with search terms
4. Expected output sections

Ask: "Does this plan look correct? Adjust scope, research areas, or search terms if needed."

## Output

The plan at `.research/<topic-slug>/plan.md` is the contract for the orchestrator and all subagents.
