---
name: research-note-template

description: >-
  **WORKFLOW SKILL** — Extract structured research notes from a source URL or
  document into a standardized YAML-frontmatter markdown note. Applies fixed
  extraction rules for consistent note-taking across all research areas. WHEN:
  "create research note", "extract research note", "note from URL",
  "research note template", "take research notes", "extract findings from".
  INVOKES: microsoft_docs_search, microsoft_docs_fetch, fetch_webpage,
  editFiles. FOR SINGLE OPERATIONS: Copy the note template and fill manually.

metadata:
  author: PlagueHO
  version: "1.0"
  reference: https://github.com/PlagueHO/plagueho.copilot

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Provide the source URL and the research area (docs, tech, blogs, arch,
  samples, solutions, other). E.g., "Extract notes from
  https://learn.microsoft.com/... for the docs area".

user-invocable: true
---

# Research Note Template

Extract structured research notes from a source into the standardized note
format. Each note captures key facts, quotes, code snippets, and metadata
from a single source, ensuring consistent extraction across all research areas
and subagents.

## Prerequisites

- A source URL or document to extract from
- The research area this source belongs to (`docs`, `tech`, `blogs`, `arch`,
  `samples`, `solutions`, `other`)
- An active research plan at `.research/<topic-slug>/plan.md`

## Process

### Step 1 — Load Extraction Rules

Read [extraction-rules.md](references/extraction-rules.md) for extraction
rules, attribution requirements, and quality thresholds.

### Step 2 — Fetch Source Content

Use the appropriate tool for the research area:

| Area | Primary Tool | Fallback |
|------|-------------|----------|
| `docs` | `microsoft_docs_fetch` | `fetch_webpage` |
| `tech` | `fetch_webpage` | — |
| `blogs` | `microsoft_docs_fetch` | `fetch_webpage` |
| `arch` | `microsoft_docs_fetch` | `fetch_webpage` |
| `samples` | `microsoft_code_sample_search` | `fetch_webpage` |
| `solutions` | `fetch_webpage` | — |
| `other` | `fetch_webpage` | — |

### Step 3 — Extract Content

Apply the extraction rules to produce:

1. **Key Facts** — bullets of important technical information
2. **Quotable Passages** — exact quotes with page context
3. **Code Snippets** — relevant code with language annotation
4. **Relationships** — connections to other dimensions or topics
5. **Limitations Noted** — any caveats, constraints, or gaps mentioned
6. **Questions Raised** — follow-up questions for other research areas

### Step 4 — Write Note File

Write the note to:
`.research/<topic-slug>/notes/<area>/<note-slug>.md`

Use the template at [note-template.md](assets/note-template.md).

The `note-slug` is derived from the source title in kebab-case, truncated
to 60 characters.

### Step 5 — Update Research Log

Append an entry to `.research/<topic-slug>/log.md`:

```markdown
- [{{TIMESTAMP}}] NOTE: {{area}}/{{note-slug}} — {{source-title}} ({{url}})
```

## Output

A single structured note file in the appropriate area subdirectory, plus a
log entry recording the extraction.
