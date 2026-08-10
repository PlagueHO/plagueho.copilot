---
name: convert-prompt-to-skill

description: >-
  **WORKFLOW SKILL** — Convert an existing GitHub Copilot prompt file
  (.prompt.md) into a conformant Agent Skill (SKILL.md) following the
  agentskills.io specification. Evaluates prompt suitability before
  conversion and scaffolds the full skill directory. WHEN: "convert prompt
  to skill", "turn prompt into skill", "make skill from prompt", "prompt
  to skill", "upgrade prompt to skill", "transform prompt to skill",
  "migrate prompt to skill". INVOKES: run_in_terminal for scaffolding
  scripts. FOR SINGLE OPERATIONS: Manually create the SKILL.md file.

metadata:
  author: plagueho.os
  version: "1.0"
  reference: https://agentskills.io/specification

compatibility:
  - GitHub Copilot
  - GitHub Copilot CLI
  - VS Code

argument-hint: >-
  Provide the path to the .prompt.md file to convert (e.g.,
  .github/prompts/my-prompt.prompt.md) and optionally where to save the
  skill (e.g., .github/skills/).

user-invocable: true
---

# Convert Prompt to Skill

Convert an existing GitHub Copilot prompt file (`.prompt.md`) into a
conformant [Agent Skill](https://agentskills.io/specification). The workflow
reads the prompt, evaluates whether it is suitable for conversion, and — if
appropriate — scaffolds a skill directory, writes the `SKILL.md`, creates
bundled assets, and validates the result.

## Prerequisites

- **PowerShell 7+** (Windows) or **Bash** (macOS/Linux) for scaffolding
  scripts.
- **Node.js** (optional, for `npx skills-ref validate`).

## Process

### Step 0 — Read the Prompt

1. Read the target `.prompt.md` file.
2. Parse the YAML frontmatter to extract: `description`, `agent`, `tools`,
   `argument-hint`, and any other metadata.
3. Parse the Markdown body to identify: purpose, inputs, step-by-step
   instructions, outputs, validation checks, and edge cases.
4. Record a summary of the prompt's intent, complexity, and structure.

### Step 1 — Evaluate Suitability

Before converting, determine whether the prompt **should** become a skill.
A prompt is a good skill candidate when it meets **most** of these criteria:

#### Criteria FOR Conversion (Skill Indicators)

| # | Criterion | Rationale |
|---|-----------|-----------|
| 1 | **Multi-step workflow** — The prompt defines 3+ ordered steps with decisions or branching | Skills excel at encoding procedural knowledge agents follow step-by-step |
| 2 | **Reusable across projects** — The instructions are not specific to a single repo or one-off task | Skills are portable; prompts tied to one context are better left as prompts |
| 3 | **Produces or transforms files** — The workflow creates, modifies, or generates artifacts | Skills can bundle scripts and templates that help produce outputs |
| 4 | **Benefits from bundled assets** — Would gain value from scripts, templates, reference docs, or static resources | Prompts cannot bundle assets; skills can |
| 5 | **Domain expertise** — Encodes specialized knowledge that agents wouldn't have by default | Skills package domain knowledge for on-demand loading |
| 6 | **Repeatable with variations** — The same process applies to different inputs or contexts | Skills handle parameterized, repeatable workflows well |
| 7 | **Tool orchestration** — Coordinates multiple tools or commands in sequence | Skills provide structured guidance for multi-tool workflows |

#### Criteria AGAINST Conversion (Prompt Indicators)

| # | Criterion | Rationale |
|---|-----------|-----------|
| 1 | **Simple, single-action task** — The prompt is a quick one-shot instruction (< 3 steps) | A prompt is simpler and more appropriate for lightweight instructions |
| 2 | **Context-specific** — Heavily depends on a specific repo, file, or user context variable (`${input:...}`) that cannot be generalized | Skills should be portable |
| 3 | **Conversational or advisory** — The prompt asks for analysis, opinions, or recommendations without producing artifacts | Skills are action-oriented workflows |
| 4 | **Already well-served by a prompt** — The task works well as a prompt and gains nothing from skill features | Avoid unnecessary complexity |

#### Decision

- **3+ FOR criteria met AND 0 AGAINST criteria**: Convert — proceed to Step 2.
- **3+ FOR criteria met AND 1+ AGAINST criteria**: Borderline — present the
  assessment to the user with a recommendation and ask for guidance.
- **< 3 FOR criteria met**: **STOP** — explain why the prompt is better kept
  as a prompt. Present the assessment table and ask the user whether they want
  to proceed anyway or keep it as a prompt.

When stopping, output:

```markdown
## Suitability Assessment

| # | Criterion | Met? | Notes |
|---|-----------|------|-------|
| FOR-1 | Multi-step workflow | Yes/No | <explanation> |
| FOR-2 | Reusable across projects | Yes/No | <explanation> |
| FOR-3 | Produces or transforms files | Yes/No | <explanation> |
| FOR-4 | Benefits from bundled assets | Yes/No | <explanation> |
| FOR-5 | Domain expertise | Yes/No | <explanation> |
| FOR-6 | Repeatable with variations | Yes/No | <explanation> |
| FOR-7 | Tool orchestration | Yes/No | <explanation> |
| AGAINST-1 | Simple, single-action task | Yes/No | <explanation> |
| AGAINST-2 | Context-specific | Yes/No | <explanation> |
| AGAINST-3 | Conversational or advisory | Yes/No | <explanation> |
| AGAINST-4 | Already well-served by a prompt | Yes/No | <explanation> |

**Result**: <Convert / Borderline / Keep as prompt>
**Recommendation**: <Explanation of the recommendation>
```

### Step 2 — Plan the Skill

Map the prompt structure to skill components:

1. **Derive `name`** from the prompt filename or purpose: lowercase, hyphens
   for spaces, 1–64 characters, no leading/trailing/consecutive hyphens.
2. **Draft `description`** — rewrite the prompt's description to follow skill
   description best practices:
   - State **what** the skill does AND **when** to use it.
   - Include trigger keywords for agent discovery.
   - Use the format: `**WORKFLOW SKILL** — <what>. WHEN: <trigger phrases>.
     INVOKES: <tools>. FOR SINGLE OPERATIONS: <alternative>.`
3. **Map prompt sections to skill structure**:

   | Prompt Element | Skill Equivalent |
   |---------------|------------------|
   | Frontmatter `description` | Frontmatter `description` (rewritten) |
   | Frontmatter `tools` | Referenced in body instructions (not `allowed-tools`) |
   | Frontmatter `argument-hint` | Frontmatter `argument-hint` |
   | `## Input` section | `## Prerequisites` or step parameter descriptions |
   | `## Step N` sections | `### Step N —` sections under `## Process` |
   | Output format / template | `## Output Format` section or `assets/` templates |
   | Validation instructions | `## Validation` section or a test script |

4. **Plan bundled assets**:

   | Directory | When to include |
   |-----------|-----------------|
   | `scripts/` | Prompt references terminal commands or repeatable automation |
   | `references/` | Background material that would push SKILL.md past 500 lines |
   | `assets/` | Static files the prompt consumes or produces |

   If scripts are needed, plan both PowerShell (`.ps1`) and Shell (`.sh`)
   variants for cross-platform support.

5. **Confirm with the user**: *"Here is the conversion plan: `<directory
   tree>`. The skill name will be `<name>`. Should I proceed?"*

### Step 3 — Scaffold the Skill

Use the skill-creator scaffolding scripts to create the directory structure.

**PowerShell** (Windows):

```powershell
& "<skill-creator-path>/scripts/New-AgentSkill.ps1" `
    -Name "<skill-name>" `
    -Description "<description>" `
    -OutputPath "<target-parent-directory>" `
    -Author "<author>" `
    -IncludeScripts `
    -IncludeReferences `
    -IncludeAssets
```

**Shell** (macOS/Linux):

```bash
"<skill-creator-path>/scripts/new-agent-skill.sh" \
    --name "<skill-name>" \
    --description "<description>" \
    --output-path "<target-parent-directory>" \
    --author "<author>" \
    --include-scripts \
    --include-references \
    --include-assets
```

Only include the `--include-*` flags for asset directories identified in
Step 2.

### Step 4 — Write the SKILL.md Body

Edit the scaffolded `SKILL.md` to convert the prompt content into skill
instructions. Follow these guidelines:

#### Frontmatter Mapping

| Source (Prompt) | Target (Skill) | Transformation |
|----------------|-----------------|----------------|
| `description` | `description` | Rewrite: add trigger keywords, use WORKFLOW SKILL format |
| `agent` | — | Drop (not a skill field) |
| `tools` | — | Drop from frontmatter; reference tools in body instructions instead |
| `argument-hint` | `argument-hint` | Keep or adapt for skill context |

> **Do NOT include `allowed-tools`** in generated skills — this field is not
> compatible with GitHub Copilot.

#### Body Conversion Rules

1. **Convert `${input:...}` variables** — replace with step instructions that
   ask the user or derive the value from context.
2. **Convert `#tool:...` references** — replace with plain-language
   instructions describing which tool to use and how.
3. **Use imperative form** — "Read the file" not "You should read the file".
4. **Add a Prerequisites section** — list tools, runtimes, or access needed.
5. **Add a Process section** — restructure prompt steps under `### Step N —`
   headings with clear decision points.
6. **Add edge cases** — extract from the prompt or infer from the workflow.
7. **Add validation** — convert any verification steps; add a validation
   checklist if the prompt lacks one.
8. **Keep under 500 lines** — move detailed reference material to
   `references/` files.

#### Progressive Disclosure

Design for efficient context use across three loading levels:

1. **Metadata** (~100 tokens): `name` + `description` — always loaded.
2. **SKILL.md body** (< 5000 tokens recommended): Full instructions — loaded
   on activation.
3. **Bundled resources** (as needed): `scripts/`, `references/`, `assets/` —
   loaded on demand.

### Step 5 — Create Bundled Assets

If the plan includes bundled assets, create them now.

#### Scripts (`scripts/`)

- Extract terminal commands from the prompt into cross-platform scripts.
- Include a comment header with purpose and usage.
- Handle missing dependencies gracefully.
- **Provide both PowerShell and Shell variants.**

#### References (`references/`)

- Move detailed documentation, lookup tables, or extended examples from the
  prompt into focused reference files.
- Keep each file under 300 lines; add a table of contents if longer.

#### Assets (`assets/`)

- Extract or create templates, schemas, or static resources the skill needs.
- Keep each file under 5 MB.

### Step 6 — Validate

Run validation to ensure the skill conforms to the
[Agent Skills specification](https://agentskills.io/specification).

**Using NPX** (recommended if Node.js is available):

```bash
npx skills-ref validate "<skill-directory-path>"
```

**Manual checklist** — verify all of the following:

- [ ] Directory name is lowercase with hyphens, 1–64 characters
- [ ] `name` field matches directory name exactly
- [ ] `name` contains only lowercase letters, digits, and hyphens
- [ ] `name` does not start or end with a hyphen
- [ ] `name` does not contain consecutive hyphens (`--`)
- [ ] `description` is 1–1024 characters, non-empty
- [ ] `description` explains what the skill does AND when to use it
- [ ] `description` includes trigger keywords for agent discovery
- [ ] `SKILL.md` body is under 500 lines
- [ ] All bundled file references use relative paths from skill root
- [ ] No hardcoded credentials, secrets, or internal URLs
- [ ] Scripts (if any) exist in both PowerShell and Shell variants
- [ ] All files are under 5 MB each
- [ ] No `${input:...}` prompt variables remain in the skill
- [ ] No `#tool:...` prompt-style tool references remain (use plain language)
- [ ] No `allowed-tools` field in frontmatter
- [ ] `agent` field has been removed from frontmatter

### Step 7 — Present the Result

Show the user:

1. The generated directory tree.
2. A summary of each file and its purpose.
3. The full `description` field for review — this is the primary triggering
   mechanism.
4. A mapping of what changed from the original prompt.
5. Any trade-offs or decisions made.

Ask: *"Does this look correct? Would you like to adjust the description,
modify the steps, or include additional bundled assets?"*

### Step 8 — Handle the Original Prompt

Ask the user what to do with the original `.prompt.md` file:

- **Keep** — leave it alongside the new skill (useful if both are needed).
- **Remove** — delete the `.prompt.md` file since the skill replaces it.
- **Archive** — move it to a different location.

## Prompt-to-Skill Conversion Reference

### What Changes Between Formats

| Aspect | Prompt (`.prompt.md`) | Skill (`SKILL.md`) |
|--------|----------------------|-------------------|
| Discovery | User invokes via `/` command | Agent auto-discovers via description matching |
| Assets | Text only | Can bundle scripts, templates, references |
| Variables | `${input:...}` for user input | Step instructions or argument-hint |
| Tool refs | `#tool:toolName` syntax | Plain-language tool descriptions |
| Frontmatter | `agent`, `tools`, `description` | `name`, `description`, `metadata`, `compatibility` |
| Structure | Flexible markdown | Recommended: Prerequisites, Process, Validation |
| Activation | Explicit user invocation | Automatic or explicit |
| Portability | Per-repo `.github/prompts/` | Cross-repo via skill directories |

### Skill Name Rules

| Rule | Example | Valid? |
|------|---------|--------|
| Lowercase only | `optimize-tokens` | Yes |
| Digits allowed | `gpt4-helper` | Yes |
| Uppercase | `Optimize-Tokens` | No |
| Leading hyphen | `-optimize` | No |
| Trailing hyphen | `optimize-` | No |
| Consecutive hyphens | `optimize--tokens` | No |
| Over 64 characters | `this-is-a-very-long-...` | No |

## Skill Directory Structure Reference

```text
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable automation
│   ├── do-thing.ps1  #   PowerShell variant
│   └── do-thing.sh   #   Shell variant
├── references/       # Optional: detailed documentation
│   └── REFERENCE.md
├── assets/           # Optional: templates, schemas, static resources
│   └── template.md
└── LICENSE           # Optional: license file
```
