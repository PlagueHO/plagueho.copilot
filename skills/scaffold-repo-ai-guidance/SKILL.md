---
name: scaffold-repo-ai-guidance

description: >-
  **WORKFLOW SKILL** — Scaffold AGENTS.md and .github/copilot-instructions.md
  by analysing repo structure, code patterns, CI pipeline, and conventions.
  Generates non-overlapping guidance so agents and code review produce
  compliant code. WHEN: "create AGENTS.md", "add copilot instructions",
  "onboard repo for Copilot", "generate copilot-instructions.md", "scaffold
  repo AI instructions", "add agent instructions to my repo". INVOKES: file
  read, semantic_search, fetch_webpage. FOR SINGLE OPERATIONS: Edit
  .github/copilot-instructions.md directly.

metadata:
  author: plagueho.os
  version: "1.0"
  reference: https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Run in the repository root. Optionally name the tech stack, e.g.
  "TypeScript monorepo" or "Python FastAPI service".

user-invocable: true
---

# Scaffold Repo AI Guidance

Generate `AGENTS.md` and `.github/copilot-instructions.md` for any repository
by examining its source, patterns, CI pipeline, and conventions. The two files
serve distinct purposes — never duplicate content between them:

- **`AGENTS.md`** (repo root): broad operational guide recognised by all AI
  agents — directory layout, exact build/test/lint commands, CI invariants,
  atomic checklists, conventions table.
- **`.github/copilot-instructions.md`**: project-specific authoring guide
  tailored to Copilot chat and code review — coding patterns, naming
  conventions, framework specifics, anti-patterns, security rules.

Bundled template files live in `assets/` relative to this skill:

- `assets/AGENTS.template.md` — starting skeleton for `AGENTS.md`
- `assets/copilot-instructions.template.md` — starting skeleton for
  `.github/copilot-instructions.md`

## Step 1 — Check for Existing Files

Before any analysis, check the repo root for `AGENTS.md` and
`.github/copilot-instructions.md`.

- **If a file exists**: read it, preserve any content the user has written, and
  improve it in-place based on what the repo analysis reveals.
- **If a file does not exist**: read the corresponding template from `assets/`
  and use it as the starting skeleton. Replace every placeholder (marked with
  `[brackets]` and `<!-- comments -->`) with repo-specific content.

## Step 2 — Discover the Repository

Read these in priority order. Aim for 10–15 files; stop a category once you
have sufficient context.

**Documentation** — `README.md`, `CONTRIBUTING.md`, existing `AGENTS.md`,
existing `.github/copilot-instructions.md`

**Build and CI** — `.github/workflows/*.yml`, `Makefile`, `Taskfile.yml`,
`azure-pipelines.yml`, `Jenkinsfile`; package manifests: `package.json`,
`pyproject.toml`, `go.mod`, `Cargo.toml`, `*.csproj`, `pom.xml`

**Lint and format configs** — `.eslintrc*`, `.prettierrc*`, `.editorconfig`,
`.markdownlint.json`, `.golangci.yml`, `ruff.toml`, `stylecop.json`

**Sample source files** — 2–3 representative files from the main source tree
that show typical naming, structure, and comment style

**Directory structure** — list the repo root; list one level inside each major
subdirectory

Extract:

- Project purpose and primary language/framework
- Exact bootstrap, build, test, and lint commands
- CI steps and which checks will fail a PR
- Directory structure and naming conventions (kebab-case, PascalCase, etc.)
- Code patterns: indent size, quote style, import order, error handling style
- Any content in existing files that must be preserved

## Step 3 — Apply Best-Practice Principles

Read the full reference at `references/best-practices.md`. Key principles to
follow while writing both files:

**AGENTS.md — critical rules:**

- Target under 100 lines; hard limit 150. Longer files reduce agent adherence.
- Lead with exact, validated build/test/lint commands — highest-value content.
- Prefer single-file commands (fast loops) over full-project builds where
  possible.
- Be concrete and verifiable: `"Use 2-space indentation"` not `"Format code
  properly"`.
- Use `##` headers, `-` bullets, `| tables |` — agents scan structure.
- Front-load critical rules — some consumers read only the first 4K characters.
- Include do/don't rules, reference real example files (good AND bad), and
  specify permission boundaries (what agents can do without asking).
- Add a rule the second time you see an agent make the same mistake.

**copilot-instructions.md — critical rules:**

- Code review reads only the first **4,000 characters** — put security and
  breaking-convention rules at the top.
- Target under 100 lines. Start with 10–20 specific instructions; expand
  iteratively.
- Write short imperative bullets, not narratives. Use `// Avoid` + `// Prefer`
  code examples for non-obvious patterns.
- Do NOT include: build commands, directory layouts, UX/formatting
  instructions, vague quality advice, external URLs, task-specific prompts.
- Copilot is non-deterministic — write instructions that stay useful even when
  occasionally missed.
- Code review uses the **base branch's** instructions, not the PR branch's.
- Precedence: Personal > Path-specific > Repository-wide > AGENTS.md > Org.

**Both files — never violate:**

- No duplicated content between the two files.
- No contradictions between any instruction files in the repo.
- No secrets, tokens, or internal URLs.
- Treat as living documentation — grow from observed mistakes, not up-front
  design.

## Step 4 — Plan the Content Split

Decide which guidelines belong where before writing anything:

| Goes in AGENTS.md | Goes in copilot-instructions.md |
|---|---|
| Directory layout tree | Repo purpose and stack summary |
| Build/test/lint commands | Naming conventions with examples |
| CI checks that must pass | Framework-specific patterns |
| Atomic change checklists | Anti-patterns to avoid |
| "Must run after change" reminders | Security and quality rules |
| Conventions table (scannable) | Code-style specifics (quotes, indent) |

Rule of thumb: if following the guideline requires running a command → `AGENTS.md`.
If it shapes what generated code looks like → `copilot-instructions.md`.

## Step 5 — Write AGENTS.md

If no `AGENTS.md` exists, read the template from `assets/AGENTS.template.md`
and copy it to the repo root. Then fill in every placeholder.

If an existing `AGENTS.md` was found in Step 1, improve it in-place — do not
discard user content.

Use the template's structural sections (Layout, Commands, Checklist, CI
Pipeline, Conventions). The template includes HTML comments explaining each
section; remove the comments once filled in.

Writing rules:

- Keep under 100 lines; hard limit 150
- Use code blocks for every command — no inline commands in prose
- Use tables for conventions — they are fast to scan
- Bold any rule whose violation will fail CI
- Omit boilerplate advice ("handle errors") — only include repo-specific rules

## Step 6 — Write .github/copilot-instructions.md

Create `.github/` if needed. If no `copilot-instructions.md` exists, read the
template from `assets/copilot-instructions.template.md` and copy it to
`.github/copilot-instructions.md`. Then fill in every placeholder.

If an existing file was found in Step 1, improve it in-place.

Use the template's structural sections (Purpose, Code Style, Naming,
Framework Patterns, Testing, Security). Remove HTML comments once filled.

Writing rules:

- Do NOT include build commands or directory layouts — those are in `AGENTS.md`
- Reference `AGENTS.md` at the top: *"See AGENTS.md for layout and commands."*
- Include before/after examples only for non-obvious patterns
- Keep under 100 lines; hard limit 150
- Omit generic advice ("write clean code") — only include repo-specific rules
  that are clearly visible in the source inspection

## Step 7 — Validate

Run the lint command found in Step 1. Common patterns:

```bash
pnpm lint:md          # Markdown repos
npm run lint          # Node.js projects
ruff check .          # Python projects
golangci-lint run     # Go projects
```

Check both generated files:

- No content duplicated across the two files
- Newline at end of file; no trailing whitespace
- Each file under 150 lines
- No secrets, tokens, or internal URLs

## Step 8 — Present Results

Show the user:

1. Files created or updated (`AGENTS.md`, `.github/copilot-instructions.md`)
2. Brief rationale for key decisions — what you included and why you placed it
   where you did
3. Lint output from Step 6
4. Ask: *"Does this look correct? Should I adjust the focus, add more detail to
   any section, or remove anything?"*
