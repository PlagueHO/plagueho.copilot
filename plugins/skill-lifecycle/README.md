# Skill Lifecycle Plugin

Skill authoring plugin that creates, converts, generates, and reviews Agent Skills.

## Installation

```bash
# Using Copilot CLI
copilot plugin install skill-lifecycle@plagueho-copilot
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/skill-lifecycle:skill-creator` | Create a new Agent Skill from a description and goal, following the agentskills.io specification. Scaffolds directory structure, generates SKILL.md with YAML frontmatter, and validates the result. |
| `/skill-lifecycle:convert-prompt-to-skill` | Convert an existing GitHub Copilot prompt file (.prompt.md) into a conformant Agent Skill (SKILL.md) following the agentskills.io specification. |
| `/skill-lifecycle:create-skill-from-pr` | Generate a reusable GitHub Copilot Agent Skill from a single-purpose refactoring or tech debt Pull Request. |
| `/skill-lifecycle:review-agent-skills` | Review explicit skills or a skill collection for portability, quality, reliability, token use, and cross-skill consistency. Produce read-only findings with rule IDs and fix guidance. |

### Review Checker Setup

The review skill bundles one Node.js 20+ frontmatter checker with PowerShell 7+ and Bash launchers. It does not execute reviewed scripts or install dependencies automatically. Install its declared YAML dependency through your approved package source before use.

From the installed skill's `scripts` directory, run:

```bash
npm install --ignore-scripts --package-lock=false
```

In this source repository, `pnpm install` supplies the same dependency for development. An installed plugin needs its own setup; it does not depend on the catalog checkout.

Supply explicit skill directories or `SKILL.md` files. For example, from the checker directory:

```powershell
./check-frontmatter.ps1 -SkillPath .. -Profile catalog
```

```bash
bash check-frontmatter.sh --profile catalog -- ..
```

Replace `..` with your target skill path. The default `standard` profile checks the open format. The optional `catalog` profile adds this catalog's conventions without suppressing standard findings. For other repositories, inspect their local policy separately.

The checker returns JSON with rule states, findings, and one-based source lines. Exit code 0 means no deterministic rules failed; 1 means rule failures; 2 means invalid input or an execution blocker.

This JSON is evidence for the bundled report template, not proof of runtime behavior. The full review also applies judgment checks and, for multiple skills, consistency, shared-knowledge, and overlap checks.

The full review is the default, including requests to "check this skill" or "use the skill checker." Frontmatter-only mode requires an explicit user limit. A checker failure does not end the full review: inspect readable source and in-scope resources, including explicitly supplied non-standard Markdown skill filenames.

Before finishing, account for every catalog rule in the ledger and complete all available checks. Give specific blockers and next actions for unavailable checks. Report incomplete verification and provisional affected scores rather than claiming that a checker-only run is a full review.

Full reviews include a token-budget table for metadata, body, entry file, required references, conditional loads, and package text inventory. They warn at 5,000 body tokens or 500 body lines, and at 5,000 tokens of required context.

These are quality warnings, not format errors or proof of poor performance. Counts identify their tokenizer or estimate method; rough estimates do not establish an exact token verdict.

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
