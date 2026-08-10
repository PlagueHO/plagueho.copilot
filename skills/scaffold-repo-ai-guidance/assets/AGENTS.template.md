# [Repository Name] — Agent Instructions

<!-- AGENTS.md — Operational guide for AI agents executing tasks in this repo.
     Loaded automatically by agentic runtimes. Keep under 150 lines.
     For code style and patterns, see .github/copilot-instructions.md. -->

## Layout

```text
repo-root/
├── src/                   # [Primary source code]
├── tests/                 # [Test suites]
├── docs/                  # [Documentation]
├── scripts/               # [Build/deploy automation]
├── .github/
│   ├── workflows/         # [CI/CD pipelines]
│   └── copilot-instructions.md
├── package.json           # [Package manifest — replace with your manifest]
└── AGENTS.md
```

<!-- Replace the tree above with the actual directory layout.
     Include only structural paths — omit individual source files. -->

## Commands

Always run after making changes:

```bash
# Bootstrap
[install command, e.g.: npm install / pip install -e ".[dev]" / go mod download]

# Build
[build command, e.g.: npm run build / dotnet build / go build ./...]

# Test
[test command, e.g.: npm test / pytest / go test ./...]

# Lint
[lint command, e.g.: npm run lint / ruff check . / golangci-lint run]
```

<!-- Replace placeholders with exact verified commands.
     Agents trust these — verify each command works before committing. -->

## Modifying [Feature Type] — Checklist

<!-- Replace [Feature Type] with the primary unit of work, e.g.
     "Adding an API Endpoint", "Adding a Module", "Adding a Skill". -->

1. [Create/modify the source file at the correct path]
1. [Update any manifest or registry that tracks these items]
1. [Add or update tests]
1. [Run lint and tests — both must pass]
1. [Update documentation if public API changed]

## CI Pipeline

<!-- List each CI check. Bold the check name. Explain what causes failure. -->

- **[Check name]**: [What it validates — e.g., "runs `npm test`; fails on any test failure"]
- **[Check name]**: [What it validates]
- **[Check name]**: [What it validates]

## Conventions

| Concern | Rule |
|---------|------|
| Naming | [e.g., kebab-case for files, PascalCase for classes] |
| Indentation | [e.g., 2 spaces for YAML/JSON, 4 spaces for source] |
| Line endings | [e.g., LF; newline at end of file; no trailing whitespace] |
| Scripts | [e.g., always provide cross-platform variants] |
| Commit messages | [e.g., Conventional Commits format] |

<!-- Only include conventions whose violation will cause review rejection or
     CI failure. Omit generic advice already enforced by linters. -->
