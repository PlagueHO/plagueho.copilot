# Skills

This directory contains GitHub Copilot Agent Skill definitions for use across
repositories. Skills are self-contained folders of instructions, scripts, and
resources that Copilot loads on-demand when relevant to a task.

## What Are Agent Skills?

Agent Skills are folders containing a `SKILL.md` file and optional bundled assets
(scripts, templates, reference data) that teach GitHub Copilot to perform tasks
in a specific, repeatable way. They follow the open
[Agent Skills specification](https://agentskills.io/specification).

Key characteristics:

- **Portable** — works across VS Code, Copilot CLI, and Copilot coding agent
- **Progressive loading** — only loaded when relevant to the user's request
- **Resource-bundled** — can include scripts, templates, and examples alongside instructions
- **On-demand** — activated automatically based on prompt relevance or invoked explicitly

### Skills vs Instructions vs Agents

| Feature | Instructions | Skills | Custom Agents |
|---------|-------------|--------|---------------|
| When loaded | Always (matching file patterns) | Automatically when relevant | When explicitly selected |
| Best for | Coding standards, style guides | Specialized task guidance | Role-based personas |
| Can include scripts | No | Yes | No (but can reference skills) |
| Scope | File-pattern based | Task-based | Session-wide |

## Structure

Each skill lives in its own subdirectory:

```text
skills/
├── README.md                    # This file
└── <skill-name>/
    ├── SKILL.md                 # Required — main instructions
    ├── LICENSE.txt              # Recommended — license terms
    ├── scripts/                 # Optional — executable automation
    │   └── helper.ps1
    ├── references/              # Optional — docs loaded into context
    │   └── api-reference.md
    ├── assets/                  # Optional — static files used as-is
    │   └── baseline.png
    └── templates/               # Optional — starter code the agent customizes
        └── scaffold.py
```

## SKILL.md Format

Every `SKILL.md` is a Markdown file with **YAML frontmatter**.

Minimal (required fields only):

```yaml
---
name: my-skill-name
description: >
  Clear description of what the skill does and when to use it.
  Include trigger keywords so agents discover it automatically.
---
```

With optional fields:

```yaml
---
name: my-skill-name
description: >
  Clear description of what the skill does and when to use it.
  Include trigger keywords so agents discover it automatically.
license: MIT
compatibility: Requires PowerShell 7+, Az PowerShell modules, and internet access
metadata:
  author: my-org
  version: "1.0"
---
```

| Field | Required | Constraints |
|-------|----------|-------------|
| `name` | Yes | Max 64 characters. Lowercase letters, numbers, and hyphens only. Must not start or end with a hyphen, no consecutive hyphens. Must match the parent directory name. |
| `description` | Yes | Max 1024 characters. Describes **what** the skill does and **when** to use it. Include specific keywords that help agents identify relevant tasks. |
| `license` | No | License name (e.g. `MIT`, `Apache-2.0`) or reference to a bundled `LICENSE.txt`. |
| `compatibility` | No | Max 500 characters. Indicates environment requirements: intended product, required system packages, network access needs, etc. Omit if the skill has no specific requirements. |
| `metadata` | No | Arbitrary key-value map for additional properties (e.g. `author`, `version`). Use reasonably unique key names to avoid conflicts. |

The Markdown body contains the detailed instructions, step-by-step workflows,
examples, and guidelines for Copilot to follow.

### Description Best Practices

- State the capability clearly: *"Update Azure Verified Modules to latest versions in Bicep files."*
- Include trigger phrases: *"Use when asked to update, upgrade, or check AVM module versions."*
- Add relevant keywords so agent discovery succeeds

### Content Guidelines

- Keep `SKILL.md` body under 500 lines — split large workflows into `references/` files
- Use step-by-step numbered instructions for workflows
- Include before/after code examples where applicable
- Specify tool usage explicitly (e.g., `read_file`, `grep_search`, `run_in_terminal`)
- Document edge cases and when to pause for user input

## Adding a New Skill

1. Create a new subdirectory under `skills/` (lowercase, hyphens for spaces)
2. Add a `SKILL.md` file with valid frontmatter and instructions
3. Optionally add scripts, templates, or reference files to the skill directory
4. Update the [Available Skills](#available-skills) table below

### Validation Checklist

- [ ] Folder name is lowercase with hyphens
- [ ] `name` field matches folder name exactly
- [ ] `description` is 10–1024 characters and explains what and when
- [ ] Body content is under 500 lines
- [ ] Bundled assets are under 5 MB each
- [ ] No hardcoded credentials or secrets
- [ ] Relative paths used for all resource references

## Available Skills

| Skill | Description |
|-------|-------------|
| [azure-github-managed-identity](azure-github-managed-identity/SKILL.md) | Creates Azure User Assigned Managed Identities with OIDC federated credentials and RBAC roles to enable GitHub Actions and GitHub Copilot coding agents to authenticate to Azure without static secrets. |
| [create-skill-from-pr](create-skill-from-pr/SKILL.md) | Generate a new Agent Skill from a GitHub PR representing a single refactoring or tech debt remediation task |

## Reference Documentation

### Official GitHub Documentation

- [About Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
  — overview of what skills are and how Copilot uses them
- [Creating Agent Skills for GitHub Copilot](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-skills)
  — step-by-step guide to creating and adding a skill
- [Creating Agent Skills for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-skills)
  — CLI-specific skill creation guidance
- [Copilot Customization Cheat Sheet](https://docs.github.com/en/copilot/reference/customization-cheat-sheet)
  — quick comparison of skills, agents, instructions, and prompt files

### Agent Skills Specification

- [Agent Skills Specification (agentskills.io)](https://agentskills.io/specification)
  — the open standard that defines the skill format

### Community Resources

- [skillmd.io](https://skillmd.io/)
  — the SKILL.md registry: browse and discover agent skills from the community indexed
  from public GitHub repositories, with categorised search across coding, testing, DevOps,
  productivity, and more.
- [github/awesome-copilot — skills](https://github.com/github/awesome-copilot/tree/main/skills)
  — community-curated collection of ready-to-use agent skills for GitHub Copilot.
  The accompanying
  [learning hub](https://github.com/github/awesome-copilot/tree/main/website/src/content/learning-hub)
  includes in-depth guides such as
  [Creating Effective Skills](https://github.com/github/awesome-copilot/tree/main/website/src/content/learning-hub/creating-effective-skills.md)
  and
  [What Are Agents, Skills, and Instructions](https://github.com/github/awesome-copilot/tree/main/website/src/content/learning-hub/what-are-agents-skills-instructions.md).
- [anthropics/skills](https://github.com/anthropics/skills)
  — Anthropic's collection of agent skills for Claude, compatible with the open Agent Skills
  specification.
