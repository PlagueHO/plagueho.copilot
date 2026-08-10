# GitHub Workflows Plugin

GitHub workflow skills for PR review evaluation, Dependabot PR management, Copilot resource optimization, and AI guidance scaffolding.

## Installation

```bash
# Using Copilot CLI
copilot plugin install github-workflows@plagueho-os
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/github-workflows:evaluate-pr-review-comments` | Evaluate review comments on a GitHub Pull Request, classifying each by validity, category, impact, and risk, then recommending whether to apply, consider, or skip. |
| `/github-workflows:merge-dependabot-prs` | Merge all Dependabot PRs in a repository in parallel. Approves and squash merges passing PRs, requests rebase for conflicting PRs, and triages failing builds. |
| `/github-workflows:optimize-github-copilot-resources` | Optimize GitHub Copilot resources such as prompts, skills, agents, and instructions for minimal token count, clarity, and AI readability. |
| `/github-workflows:release-changelog` | Review commits since the last version tag, update CHANGELOG.md following Keep a Changelog format, then commit, tag, and push to trigger deployment. |
| `/github-workflows:scaffold-repo-ai-guidance` | Scaffold AGENTS.md and .github/copilot-instructions.md by analysing repo structure, code patterns, CI pipeline, and conventions. |

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [plagueho.os](https://github.com/PlagueHO/plagueho.os), organizational assets for Daniel Scott-Raynsford.

## License

MIT
