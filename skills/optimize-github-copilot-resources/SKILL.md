---
name: optimize-github-copilot-resources
description: "**WORKFLOW SKILL** — Optimize GitHub Copilot resources such as prompts, skills, agents, and instructions for minimal token count, clarity, and AI readability. WHEN: \"optimize tokens\", \"reduce prompt size\", \"minimize token count\", \"shrink prompt\", \"optimize Copilot resources\", \"reduce verbosity\", \"improve readability\". INVOKES: file read, file edit tools. FOR SINGLE OPERATIONS: manual find-and-replace of filler words."
argument-hint: 'Provide the file path to the prompt, skill, agent, or instruction file to optimize (e.g., .github/prompts/my-prompt.prompt.md)'
---

# Optimize GitHub Copilot Resources

Optimize a GitHub Copilot resource such as a prompt (`.prompt.md`), skill
(`SKILL.md`), agent definition (`.agent.md`), or instruction file
(`copilot-instructions.md`, `*.instructions.md`) for minimal token count,
maximum clarity, and AI readability.

**Primary constraint**: The optimized output must retain 100% of the
functionality, capability, and constraints of the original. The agent consuming
the optimized definition must produce identical behavior. Never remove, weaken,
or generalize an instruction.

## Prerequisites

- **File read tool**: Ability to read the target file.
- **File edit tool**: Ability to edit file contents in place.
- **Search tool**: Ability to search file contents for patterns.
- **Target file**: A `.prompt.md`, `SKILL.md`, `.agent.md`,
  `copilot-instructions.md`, or `*.instructions.md` file to optimize.

## Process

### Step 1 — Read and Baseline

1. Read the target file.
2. Count the approximate token count (estimate 1 token per 4 characters).
3. Record the baseline token estimate.
4. Note the current structure: heading hierarchy, section count, list types,
   code blocks, and examples.

### Step 2 — Analyze for Optimization

Read both reference files before analyzing:

- `references/optimization-patterns.md` — Token-waste patterns and replacements.
- `references/ai-readability-practices.md` — AI readability best practices.

Do not flag content that carries functional meaning, behavioral constraints, or
edge-case handling — these must remain intact regardless of verbosity.

Apply these analysis categories:

#### 2a. Token Reduction

1. **Filler language** — Filler adverbs, hedging phrases, redundant preambles,
   filler transitions, polite padding, tautologies.
2. **Verbose constructions** — Replace with concise equivalents from the
   verbose-to-concise table in the reference.
3. **Structural redundancy** — Repeated instructions, heading restatements,
   duplicate constraints (consolidate, keeping the most specific version).
4. **Unnecessary formatting** — Excessive blank lines, decorative separators,
   over-use of bold/italic, long table headers.

#### 2b. Clarity and Precision

1. **Imperative voice** — Convert passive voice to active. Convert conditional
   instructions to imperative where the condition is always true.
2. **One idea per sentence** — Break compound sentences with multiple clauses
   into separate concise sentences.
3. **Specific over vague** — Replace vague quantifiers ("some", "various",
   "several") with specific values or remove. Replace "etc." with actual items
   or remove.
4. **Tell what to do** — Prefer positive instructions over negations. Reserve
   "do not" for critical guardrails only.
5. **Remove meta-commentary** — Remove statements about the instructions
   themselves ("This section explains how to...").

#### 2c. AI Readability and Structure

1. **Section order** — Verify the definition follows the recommended order:
    Identity → Instructions → Examples → Context.
2. **Heading hierarchy** — Ensure consistent heading levels that convey
    logical structure. Each section should have a clear purpose.
3. **Structural markup** — Use Markdown headers for sections, XML tags for
    content boundaries (where appropriate), tables for structured data,
    fenced code blocks for code/commands.
4. **Progressive disclosure** — Move detailed reference material (lookup
    tables, extended examples, schemas) to `references/` files if the body
    exceeds 500 lines or ~5000 tokens. Keep the main body focused on workflow
    and constraints.
5. **Decision points** — Make branching conditions explicit with both
    branches specified. Flatten nested conditionals into decision tables
    where possible.
6. **Example quality** — Verify examples are diverse, cover edge cases, and
    are clearly separated from instructions (using tags or headings).
7. **Context placement** — Place supporting data and reference material near
    the end, after instructions and examples.

### Step 3 — Apply Optimizations

Apply all identified optimizations. Follow these constraints strictly — when in
doubt, preserve the original wording:

1. **100% functional equivalence.** Every instruction, constraint, rule,
   condition, edge case, example, and behavioral directive in the original must
   have a semantically identical equivalent in the optimized version. If an
   instruction cannot be shortened without altering its meaning, keep it as-is.
2. **Preserve all steps.** Do not remove, merge, or reorder steps. Each
   numbered step in the original must remain as a distinct numbered step.
3. **Preserve all constraints and conditions.** Do not weaken "must" to
   "should", remove conditional branches, or drop error-handling directives.
4. **Preserve frontmatter fields and values.** Do not alter YAML frontmatter
   keys. Optimize the `description` field value only if it contains filler.
5. **Preserve structural hierarchy.** Keep the same heading levels and
   numbered/bulleted list structure. Do not merge or reorder sections.
6. **Preserve code blocks and examples verbatim.** Do not alter content inside
   fenced code blocks unless it contains comments with filler language.
7. **Preserve tool references.** Do not rename, remove, or alter tool name
   references.
8. **Preserve variable interpolations.** Do not alter `${...}` expressions.
9. **Preserve trigger keywords.** In skill/agent `description` fields, retain
   all USE FOR / DO NOT USE FOR keywords — these drive invocation matching.
10. **Improve structure.** Reorder sections to follow Identity → Instructions
    → Examples → Context when the original order is suboptimal. Flag the
    reordering in the report.
11. **Improve clarity.** Rewrite unclear or ambiguous instructions into direct,
    specific statements — but only when the rewrite is unambiguously equivalent.

### Step 4 — Validate Functional Equivalence

1. Compare the optimized version against the original section-by-section.
2. For each section, verify:
   - Every instruction in the original has a corresponding instruction in the
     optimized version.
   - Every constraint ("must", "do not", "only if", "stop when") is preserved
     with identical strictness.
   - Every conditional branch and edge-case handler is present.
   - Every tool reference and `${...}` interpolation is unchanged.
   - Every step number maps 1:1 to the original.
3. Verify AI readability improvements:
   - Structure follows Identity → Instructions → Examples → Context order
     (or has a justified reason not to).
   - Heading hierarchy is consistent and meaningful.
   - Decision points have explicit branches.
   - No wall-of-text paragraphs remain (break into lists or shorter
     paragraphs).
4. If any functional content was lost, restore it before proceeding.
5. Estimate the new token count.

### Step 5 — Report

Present a summary:

| Metric | Value |
|--------|-------|
| **Original tokens (est.)** | `<count>` |
| **Optimized tokens (est.)** | `<count>` |
| **Reduction** | `<count>` (`<percent>`%) |

List the categories of changes applied:

- **Filler removed**: Count of filler words/phrases eliminated
- **Verbose → concise**: Count of verbose constructions replaced
- **Structural dedup**: Count of redundant sections/sentences consolidated
- **Voice/mood fixes**: Count of passive → active or conditional → imperative
- **Clarity improvements**: Count of ambiguous instructions rewritten
- **Structure improvements**: Count of sections reordered or restructured
- **Formatting cleanup**: Count of formatting-only changes

If any optimization was intentionally skipped to preserve clarity or
determinism, note it with the rationale.
