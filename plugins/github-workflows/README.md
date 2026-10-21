# GitHub Workflows Plugin

GitHub workflow skills for issue creation, PR review evaluation, Dependabot PR management, Copilot resource optimization, personal instruction review, and AI guidance scaffolding.

## Installation

```bash
# Using Copilot CLI
copilot plugin install github-workflows@plagueho-copilot
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/github-workflows:evaluate-pr-review-comments` | Evaluate review comments on a GitHub Pull Request, classifying each by validity, category, impact, and risk, then recommending whether to apply, consider, or skip. |
| `/github-workflows:github-create-issue` | Create clear GitHub issues using repository templates, duplicate checks, approved metadata, and ASD-STE100-aligned English. |
| `/github-workflows:improve-user-copilot-instructions` | Review recent session feedback and propose portable personal instruction changes. Apply only explicitly approved changes. |
| `/github-workflows:merge-dependabot-prs` | Merge all Dependabot PRs in a repository in parallel. Approves and squash merges passing PRs, requests rebase for conflicting PRs, and triages failing builds. |
| `/github-workflows:optimize-github-copilot-resources` | Optimize GitHub Copilot resources such as prompts, skills, agents, and instructions for minimal token count, clarity, and AI readability. |
| `/github-workflows:release-changelog` | Review commits since the last version tag, update CHANGELOG.md following Keep a Changelog format, then commit, tag, and push to trigger deployment. |
| `/github-workflows:scaffold-repo-ai-guidance` | Scaffold AGENTS.md and .github/copilot-instructions.md by analysing repo structure, code patterns, CI pipeline, and conventions. |

### Personal Instruction Review

Invoke the review when needed:

```text
/github-workflows:improve-user-copilot-instructions
```

The default review selects at most 10 sessions from the previous seven days. It includes different projects, correction cases, and verified successful cases where available. It reads current personal instructions and returns at most 10 ranked changes with supporting evidence and instruction-length costs.

The skill uses available read-only history tools. It checks `/chronicle` support but does not invoke repository-only `/chronicle improve`. If history access is unavailable, supply selected session exports. The report states sample limits, missing evidence, and incomplete instruction discovery.

Accept or ignore each recommendation by ID. The skill applies only the exact changes that you explicitly approve. It does not change repository instructions, bypass managed policy, or create an automatic schedule.

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
