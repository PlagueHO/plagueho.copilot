# Best Practices Reference

Consolidated guidance from GitHub docs, Anthropic (Claude), Builder.io, the
official agents.md spec, and Cursor — sourced April 2026.

## AGENTS.md

### What to Include

1. **Exact build/test/lint commands** — highest-value content. Validate each
   command by running it before committing. Include single-file variants where
   possible (e.g., `npx tsc --noEmit path/to/file.tsx`) for faster agent loops.
2. **Minimal directory layout** — key paths only. Think sitemap, not `tree -a`.
3. **CI checks that block merge** — name each check, explain what fails it.
4. **Atomic change checklists** — ordered steps for the primary unit of work.
5. **Conventions table** — scannable `| Concern | Rule |` format.
6. **Do/Don't list** — add a rule the second time you see the same mistake.
7. **PR/commit conventions** — title format, required checks, diff expectations.
8. **Permission boundaries** — what the agent can do without asking vs. what
   requires confirmation (package installs, `git push`, deleting files).
9. **"When stuck" guidance** — instruct agents to ask or propose a plan instead
   of pushing large speculative changes.
10. **Reference example files** — point to real files showing best patterns AND
    call out legacy files to avoid.

### What NOT to Include

- Vague advice: "handle errors gracefully", "write clean code"
- Task-specific procedures (move to skills or prompts)
- References to external repos the agent cannot access
- Duplicate of content already in `copilot-instructions.md`

### Size and Structure

- **Target**: under 100 lines. **Hard limit**: 150 lines (~200 lines absolute
  max per Anthropic). Longer files reduce adherence.
- Use `##` headers and `-` bullet lists — agents scan structure like readers.
- Front-load the most important instructions — some consumers have character
  limits.
- For monorepos, nest `AGENTS.md` in subdirectories — nearest file wins.

### Maintenance

- Treat as living documentation — grow from real mistakes, not up-front design.
- Add a rule the second time you see the same agent mistake.
- Periodically review for contradictions with other instruction files.

## copilot-instructions.md

### What to Include

1. **Project purpose** — 2–3 sentences: what the repo does, tech stack, target
   environment. Helps Copilot scope suggestions.
2. **Code style** — only non-default rules (indent size, quote style, import
   order, line length). If a formatter enforces it, one line is enough.
3. **Naming conventions** — table with Element/Convention/Example columns.
4. **Framework patterns** — 3–5 key conventions. Use do/don't code examples
   for the most important or surprising rules.
5. **Testing patterns** — framework, file co-location, naming, mocking style.
6. **Security rules** — specific to this codebase (PII logging, SQL injection
   prevention, input validation, secret handling).
7. **Concrete code examples** — `// Avoid` + `// Prefer` pairs work better
   than abstract rules.

### What NOT to Include

- Build/test/lint commands or directory layouts (those go in `AGENTS.md`)
- UX/formatting instructions ("use bold for critical issues", "add emoji") —
  explicitly unsupported by Copilot
- Vague quality meta-instructions ("be more accurate", "be consistent")
- Style/tone constraints ("answer like a friendly colleague") — unreliable in
  large repos
- External URL references — Copilot cannot follow links; copy content inline
- Task-specific prompts (use `.prompt.md` files instead)

### Size and Structure

- **Code review reads only the first 4,000 characters.** Put critical rules
  (security, breaking conventions) at the top.
- **Target**: under 100 lines. Start with 10–20 specific instructions, expand
  iteratively.
- Use short imperative bullet points, not paragraphs. `- Check for hardcoded
  secrets` not `"When reviewing code, try to look for situations where..."`.
- Whitespace is ignored by Copilot — format for human readability.

### Copilot-Specific Behaviours

- Copilot is non-deterministic — it may not follow every instruction every
  time. Write instructions that remain useful even when occasionally missed.
- Code review uses the **base branch's** instructions, not the PR branch.
  New instructions on a feature branch won't take effect until merged.
- Path-specific `.instructions.md` files support `excludeAgent` frontmatter
  to target code review or cloud agent separately.
- Precedence order: Personal > Path-specific > Repository-wide >
  Agent instructions (AGENTS.md) > Organization.

### Maintenance

- Test iteratively: open a PR, request review, observe compliance, refine.
- Don't write a 500-line file on day one — add instructions one at a time.
- Review all instruction sources together to catch contradictions.

## Content Split — Decision Table

| Guideline type | File |
|---|---|
| Requires running a command | `AGENTS.md` |
| Shapes what generated code looks like | `copilot-instructions.md` |
| Directory layout / project structure | `AGENTS.md` |
| Naming/style conventions with examples | `copilot-instructions.md` |
| CI checks and what fails them | `AGENTS.md` |
| Framework do/don't patterns | `copilot-instructions.md` |
| Atomic change checklists | `AGENTS.md` |
| Security rules (PII, injection, secrets) | `copilot-instructions.md` |
| Permission boundaries for agents | `AGENTS.md` |
| Language-specific rules (single language) | Path-specific `.instructions.md` |

## Key Difference Between the Two Files

| Aspect | `AGENTS.md` | `copilot-instructions.md` |
|---|---|---|
| Scope | All AI agents (Copilot, Claude, Cursor, Codex, etc.) | GitHub Copilot only |
| Location | Repo root (nestable in subdirs) | `.github/` only |
| Standard | Open format (Linux Foundation) | GitHub proprietary |
| Nesting | Yes — closest file wins | No (use path-specific files) |
| Precedence | Lower than `copilot-instructions.md` | Higher than `AGENTS.md` |
| Best for | Execution context (commands, layout, CI) | Authoring context (patterns, style, conventions) |

## Sources

- [GitHub: Adding repository custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [GitHub: Response customization](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [GitHub: Custom instructions support reference](https://docs.github.com/en/copilot/reference/custom-instructions-support)
- [Official agents.md specification](https://github.com/agentsmd/agents.md)
- [Anthropic: Claude Code memory (CLAUDE.md)](https://docs.anthropic.com/en/docs/agents/claude-code/memory)
- [Builder.io: The Ultimate Guide to AGENTS.md](https://www.builder.io/blog/agents-md)
