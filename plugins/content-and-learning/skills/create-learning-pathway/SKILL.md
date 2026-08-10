---
name: create-learning-pathway

description: "**WORKFLOW SKILL** — Generate structured Learning Pathway documents for Microsoft technologies, progressing L100–L400. WHEN: \"create a learning pathway\", \"build a training plan\", \"generate a study guide\", \"produce a skilling roadmap\", \"design a learning journey\". INVOKES: microsoft_docs_search, microsoft_docs_fetch, github_repo MCP tools. FOR SINGLE OPERATIONS: Use Microsoft Learn MCP directly to look up individual training modules."

metadata:
  author: PlagueHO
  version: "1.1"
  reference: https://github.com/PlagueHO/plagueho.os/

compatibility:
  - GitHub Copilot

argument-hint: >
  Provide the technology topic and an optional learning goal for the Learning
  Pathway (e.g., "Microsoft Foundry — goal: enable partners to build, evaluate,
  and deploy production agents"). If no topic is specified, I will ask you for
  one before proceeding.

user-invocable: true
---

## Overview

This skill generates a structured Learning Pathway markdown document that helps
Microsoft Partners progressively build expertise in a specific technology topic.
The pathway is organized into four levels aligned with the Microsoft skilling
framework:

| Level | Audience | Depth |
|-------|----------|-------|
| **L100 — Foundational** | Beginners with no prior exposure | Overview, concepts, value proposition |
| **L200 — Intermediate** | Practitioners starting to build | Core features, guided tutorials, first-hand experience |
| **L300 — Advanced** | Experienced practitioners | Architecture patterns, integration, production scenarios |
| **L400 — Expert** | Specialists and architects | Deep internals, optimization, complex real-world solutions |

## MCP Tools Used

| Step | Tool | Purpose |
|------|------|---------|
| 2 | `microsoft_docs_search` | Search Microsoft Learn for training modules and learning paths |
| 2 | `microsoft_docs_fetch` | Fetch full content from Microsoft Learn pages for detail |
| 3 | `github_repo` | Search first-party GitHub orgs for workshop and lab repositories |

**MCP Server (Preferred):** Use Microsoft Learn MCP tools for discovery.

**CLI Fallback (if MCP unavailable):** Manually browse `learn.microsoft.com/en-us/training/` and search GitHub directly at `github.com/MicrosoftLearning`.

## Prerequisites

- Access to Microsoft Learn MCP tools (`microsoft_docs_search`,
  `microsoft_docs_fetch`) to discover official training modules and learning
  paths.
- Access to `github_repo` tool to search for first-party Microsoft workshop and
  learning repositories on GitHub.

## CRITICAL — Topic and Goal Required

If the user has **not** specified a technology topic for the Learning Pathway,
you **MUST stop immediately** and ask:

> What technology topic would you like the Learning Pathway to cover?
> For example: Microsoft Foundry, Azure Kubernetes Service, Microsoft Fabric,
> Azure AI Search, GitHub Copilot, etc.

**Do NOT proceed** until a topic is confirmed.

Every Learning Pathway must have a **Goal** — a single sentence describing what
the learner will be able to do after completing the pathway. If the user
provides a goal, use it. If not, infer a goal from the topic and confirm it
with the user. The goal drives resource selection: every resource included in
the pathway must contribute toward this goal.

> Example goal: *"Enable Microsoft Partners to build, evaluate, and deploy
> production-grade agents using Microsoft Foundry."*

## Process

### Step 1 — Confirm the Topic and Goal

1. Identify the technology topic from the user's request or conversation
   context.
2. If the topic is ambiguous or too broad, ask the user to narrow it down
   (e.g., "Azure AI" could mean Azure AI Search, Azure AI Foundry, Azure
   OpenAI Service, etc.).
3. Identify or infer the **pathway goal** — a single sentence describing what
   the learner will achieve. If the user did not provide one, propose a goal
   and confirm it.
4. Confirm both the topic and the goal with the user before proceeding.

### Step 2 — Research Microsoft Learn Training Resources

Use the `microsoft_docs_search` tool to find official training content for the
topic. Run searches targeting training modules, learning paths, and labs:

1. Search for `"<topic> training"` to find Microsoft Learn training modules.
2. Search for `"<topic> learning path"` to find structured learning paths.
3. Search for `"<topic> tutorial"` to find hands-on tutorials.
4. Search for `"<topic> quickstart"` to find getting-started content.
5. Search for `"<topic> workshop"` to find workshop-style content.

For each result, note the:

- Title
- URL (must be under `learn.microsoft.com`)
- Description or summary
- Estimated duration (if available)
- Skill level (beginner, intermediate, advanced)
- **Relevance** — a single sentence explaining why this resource matters for
  the pathway goal

Use `microsoft_docs_fetch` to get details on promising results when the search
snippet is insufficient to determine the level or relevance.

**Prefer content from `learn.microsoft.com/en-us/training/`** (training modules
and learning paths) over product documentation. Only include product
documentation (`learn.microsoft.com/en-us/<product>/`) if the topic has a
critical gap not covered by training content.

### Step 3 — Research GitHub Workshop Repositories

Use the `github_repo` tool to search for self-paced workshops and learning
content on GitHub. Search in the following first-party organizations:

- `microsoft` — Microsoft's main GitHub org
- `Azure` — Azure GitHub org
- `Azure-Samples` — Azure sample code and workshops
- `MicrosoftLearning` — Microsoft Learning official labs
- `MicrosoftDocs` — Microsoft Docs content
- `github` — GitHub's own org (for GitHub-related topics)

Run searches such as:

1. Search `microsoft/<topic> workshop` for workshop repositories.
2. Search `Azure-Samples/<topic>` for sample and lab repositories.
3. Search `MicrosoftLearning/<topic>` for official lab exercises.

For each repository found, note the:

- Repository name and URL
- Description
- Whether it contains structured learning content (README with steps, modules,
  hands-on exercises)
- Last updated date (prefer actively maintained repos)
- Stars/popularity (as a quality signal)
- **Relevance** — a single sentence explaining why this repository matters for
  the pathway goal

**Only include repositories that contain structured learning content** such as
step-by-step workshops, hands-on labs, or guided tutorials. Do not include
libraries, SDKs, or production tools unless they contain embedded learning
material.

### Step 4 — Classify Resources by Level

Organize all discovered resources into the four levels:

**L100 — Foundational:**

- "Introduction to..." or "What is..." modules
- Overview learning paths
- Conceptual quickstarts
- Getting-started tutorials

**L200 — Intermediate:**

- "Build your first..." or "Create a..." tutorials
- Core feature learning paths
- Guided hands-on labs
- Basic architecture modules

**L300 — Advanced:**

- Integration and multi-service modules
- Architecture pattern training
- Production deployment guides
- Advanced feature deep-dives
- Multi-day workshop repos

**L400 — Expert:**

- Performance optimization content
- Security hardening and compliance
- Complex reference architectures
- Troubleshooting and debugging deep-dives
- Enterprise-scale workshops

### Step 5 — Identify Adjacent Learning Pathways

Based on the researched topic, identify 3-6 related technologies that a learner
might want to explore next. For each adjacent pathway, provide:

- Technology name
- A one-sentence description of why it's relevant
- The relationship to the main topic (e.g., "prerequisite", "complementary",
  "next step", "alternative approach")

For example, if the main topic is "Microsoft Foundry", adjacent pathways might
include: Azure AI Search, Azure OpenAI Service, Responsible AI, Prompt
Engineering, Azure API Management (for AI Gateway).

### Step 6 — Generate the Learning Pathway Document

Create a markdown file at `learning-pathways/<topic-slug>.md` where
`<topic-slug>` is the topic name in lowercase with spaces replaced by hyphens
(e.g., `microsoft-foundry.md`, `azure-kubernetes-service.md`).

Use the template defined in [references/TEMPLATE.md](references/TEMPLATE.md)
to structure the document. Ensure:

1. Every resource has a working URL.
2. Every resource has a brief description explaining what the learner will gain.
3. **Every resource has a Relevance sentence** — one sentence explaining why
   this resource was included and how it contributes to the pathway goal.
4. Resources within each level are ordered from simpler to more complex.
5. Each level contains at minimum 2 resources (if fewer exist, note the gap).
6. The document follows the consistent template format exactly.
7. Estimated time to complete each resource is included where available.
8. The pathway **Goal** from Step 1 is included in the metadata table.

### Step 7 — Review and Present

1. Review the generated document for completeness and accuracy.
2. Ensure there are no broken or speculative URLs — every link must come from
   a search result or fetch operation.
3. Present the document to the user and note any gaps where content was limited.
4. Suggest the user review the adjacent pathways section and request any of
   those as a follow-up.

## Source Priority

Resources **MUST** only come from the following sources, in priority order:

1. **Microsoft Learn Training & Labs**
   (`learn.microsoft.com/en-us/training/`) — This is the primary source.
   Training modules and learning paths should make up the majority of the
   pathway.
2. **First-party GitHub repositories** — Repos in `microsoft`, `Azure`,
   `Azure-Samples`, `MicrosoftLearning`, `MicrosoftDocs`, or `github` orgs
   that contain structured workshop or learning content.
3. **Microsoft Learn product documentation**
   (`learn.microsoft.com/en-us/<product>/`) — Use sparingly and only when a
   critical concept or procedure is not covered by the above two sources.

**Do NOT include:**

- Third-party blog posts or tutorials
- YouTube videos or podcasts
- Community-created content outside first-party Microsoft/GitHub orgs
- Paid courses or certifications (mention relevant certifications in the
  "Next Steps" section only)
- Content from non-Microsoft GitHub organizations

## Edge Cases

- **Topic too broad** — If the topic spans multiple products (e.g., "Azure AI"),
  ask the user to pick a specific sub-topic or confirm they want a broad
  overview pathway.
- **Very few resources found** — If fewer than 5 total resources are found,
  inform the user that the topic has limited official training content and
  present what's available. suggest product documentation to fill gaps.
- **Topic not a Microsoft technology** — If the requested topic is not a
  Microsoft/Azure/GitHub technology, inform the user that this skill is
  designed for Microsoft technology topics and ask if they'd like to choose a
  Microsoft technology instead.
- **Rapidly evolving topic** — For preview or recently GA'd technologies, note
  that content may change and recommend the user verify links periodically.
