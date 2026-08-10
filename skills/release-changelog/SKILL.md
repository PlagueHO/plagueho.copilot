---
name: release-changelog
description: >-
  **WORKFLOW SKILL** — Update CHANGELOG.md and tag a new release from commits
  since the last version tag. WHEN: "release version", "update changelog",
  "cut release", "tag release", "ship version", "bump version tag", "prepare
  release", "new version", "changelog update", "push release". INVOKES:
  run_in_terminal (git log, git tag, git commit, git push), read_file,
  replace_string_in_file. FOR SINGLE OPERATIONS: Use git tag and git push
  directly.
metadata:
  author: PlagueHO
  version: 1.1.0
---

# Release Changelog

Automate the release process: review commits since the last version tag, update
`CHANGELOG.md` following the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
format, then commit, tag, and push to trigger deployment.

## Process

### Step 1 — Detect the Last Release Tag

Find the most recent semantic version tag. Tags follow the pattern `vN.N.N`
(e.g., `v1.0.0`, `v2.3.1`).

```bash
git tag --list "v*" --sort=-version:refname | head -n 1
```

If no tags exist, treat every commit on the current branch as unreleased
changes. Set `LAST_TAG` to the root commit:

```bash
git rev-list --max-parents=0 HEAD | head -n 1
```

### Step 2 — List Commits Since Last Release

Retrieve all commits between the last tag and HEAD:

```bash
git log <LAST_TAG>..HEAD --oneline
```

**If there are zero commits, stop immediately** and inform the user:

> No changes since the last release (`<LAST_TAG>`). There is nothing to release.

Do not proceed further.

### Step 3 — Determine the New Version

Ask the user which version to release. Suggest the next version based on the
commits:

- **Patch** (N.N.X): dependency bumps, bug fixes, documentation changes
- **Minor** (N.X.0): new features, non-breaking changes
- **Major** (X.0.0): breaking changes

If the user has already specified the version (e.g., "release v1.0.1"), use
that directly.

### Step 4 — Check for CHANGELOG.md

Look for `CHANGELOG.md` in the repository root.

**If it does not exist**, offer to create one using the template at
`assets/CHANGELOG.md` (relative to this skill). Copy the template to the
repository root. The template follows the Keep a Changelog format described in
the reference document at `references/KEEPACHANGELOG.md`.

### Step 5 — Categorize Commits

Read the commit messages and categorize each into the Keep a Changelog change
types. Use these mapping rules:

| Commit Pattern | Changelog Category |
|---|---|
| `feat:` or `feat(...):`  | Added |
| `fix:` or `fix(...):`  | Fixed |
| `refactor:` or `perf:` | Changed |
| `deps(...):`  or dependency bumps | Dependencies |
| `docs:` or `docs(...):`  | Changed |
| `BREAKING CHANGE` or `!:` | Changed (note as breaking) |
| `deprecated` keyword | Deprecated |
| `remove` or `revert` | Removed |
| `security` keyword | Security |

Group related commits together. Summarize rather than dumping raw commit
messages. Changelogs are for humans, not machines.

The standard Keep a Changelog categories are:

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** in case of vulnerabilities

An additional **Dependencies** category may be used for dependency-only bumps
when there are many of them. This keeps the core categories clean.

Omit empty categories. Only include categories that have entries.

### Step 6 — Update CHANGELOG.md

Read the existing `CHANGELOG.md`. Insert a new version section between the
`## [Unreleased]` heading and the previous release heading. Preserve all
existing content below.

The new section format:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added

- Description of new feature

### Changed

- Description of change

### Fixed

- Description of fix

### Dependencies

- Bump `package-name` from X.Y.Z to A.B.C
```

Use today's date in ISO 8601 format (`YYYY-MM-DD`).

Each entry should be a concise, human-readable description. Do not simply copy
commit messages verbatim. Combine related commits into single entries where
appropriate.

### Step 7 — Confirm with the User

Present the updated `CHANGELOG.md` section to the user and ask for
confirmation before proceeding. Show:

1. The new version number and date
1. All categorized entries
1. The git tag that will be created
1. The branch and remote that will receive the push

Ask: *"Does this changelog look correct? Shall I commit, tag, and push?"*

### Step 8 — Commit, Tag, and Push

After user confirmation, execute the release:

```bash
git add CHANGELOG.md
git commit -m "chore(docs): release v<VERSION>"
git tag v<VERSION>
git push origin <BRANCH>
git push origin v<VERSION>
```

Use the conventional commit format `chore(docs): release v<VERSION>` for the
commit message.

### Step 9 — Confirm Completion

Report the completed release:

- Commit hash
- Tag name
- Remote push status
- Any CI/CD pipeline that the tag push should trigger

## Keep a Changelog Format Reference

For detailed guidance on the Keep a Changelog format, structure, and guiding
principles, refer to the bundled reference document at
`references/KEEPACHANGELOG.md`.

Key principles:

- Changelogs are for humans, not machines
- There should be an entry for every single version
- The same types of changes should be grouped
- Versions and sections should be linkable
- The latest version comes first
- The release date of each version is displayed in ISO 8601 format
- The project should mention whether it follows Semantic Versioning
