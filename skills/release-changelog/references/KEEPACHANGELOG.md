# Keep a Changelog Format Reference

This reference documents the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
format (version 1.1.0) for use by the `release-changelog` skill.

## What Is a Changelog

A changelog is a file containing a curated, chronologically ordered list of
notable changes for each version of a project. It is written for humans, not
machines.

## Guiding Principles

- Changelogs are for humans, not machines
- There should be an entry for every single version
- The same types of changes should be grouped
- Versions and sections should be linkable
- The latest version comes first
- The release date of each version is displayed
- Mention whether the project follows [Semantic Versioning](https://semver.org/)

## File Structure

The file should be named `CHANGELOG.md` and placed in the repository root.

### Header

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
```

### Unreleased Section

Always maintain an `## [Unreleased]` section at the top to track upcoming
changes. At release time, move entries from Unreleased into a new version
section.

```markdown
## [Unreleased]
```

### Version Sections

Each release gets its own section with the version number and date:

```markdown
## [1.0.0] - 2026-04-25
```

- Version numbers follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`
- Dates use ISO 8601 format: `YYYY-MM-DD`
- Versions are listed in reverse chronological order (newest first)

### Change Type Subsections

Group changes under these standardized headings:

| Heading | Purpose |
|---|---|
| `### Added` | New features |
| `### Changed` | Changes in existing functionality |
| `### Deprecated` | Soon-to-be removed features |
| `### Removed` | Now removed features |
| `### Fixed` | Bug fixes |
| `### Security` | Vulnerability patches |

Only include headings that have entries. Omit empty sections.

### Entry Format

Each entry is a bullet point with a concise, human-readable description:

```markdown
### Added

- User authentication via Microsoft Entra ID
- Dark mode toggle in settings page

### Fixed

- WebSocket reconnection loop when token expires
```

## Complete Example

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-04-25

### Added

- Speech-to-text streaming via WebSocket
- Template management with built-in defaults

### Changed

- Migrate from REST polling to SSE for prompt generation

### Fixed

- Memory leak in audio recording hook

## [1.0.0] - 2026-04-20

### Added

- Initial release with transcription and prompt generation
```

## Anti-Patterns to Avoid

### Dumping Commit Logs

Commit messages serve a different purpose than changelog entries. Commits
document steps in code evolution; changelog entries document noteworthy
differences communicated to end users. Summarize and curate rather than copying
git log output verbatim.

### Ignoring Deprecations

When upgrading from one version to another, breaking changes should be
painfully clear. List deprecations in the version where they are introduced,
then list removals in the version where deprecated features are actually
removed.

### Confusing Dates

Regional date formats vary throughout the world and it is often difficult to
find a human-friendly date format that feels intuitive to everyone. Dates
formatted like `2017-07-17` follow the order of largest to smallest units:
year, month, and day. This format does not overlap in ambiguous ways with other
regional formats that switch the position of month and day numbers. These
reasons, and the fact that this date format is an
[ISO standard](https://www.iso.org/iso-8601-date-and-time-format.html), make it
the recommended date format for changelog entries.

### Inconsistent Changes

A changelog that only mentions some of the changes can be as dangerous as not
having a changelog. While many of the changes may not be relevant — for
instance, removing a single whitespace may not need to be recorded in all
instances — any important changes should be mentioned in the changelog. By
inconsistently applying changes, your users may mistakenly think that the
changelog is the single source of truth. It ought to be. With great power comes
great responsibility — having a good changelog means having a consistently
updated changelog.

### Empty Sections

Omit change type headings that have no entries. Empty sections add noise
without value.

## Yanked Releases

If a release must be pulled due to a serious bug or security issue, mark it:

```markdown
## [0.5.0] - 2026-03-15 [YANKED]
```

The `[YANKED]` tag is intentionally loud so readers notice it immediately.

## Comparison Links

Optionally, include comparison links at the bottom of the file to make
versions linkable:

```markdown
[unreleased]: https://github.com/owner/repo/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/owner/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/owner/repo/releases/tag/v1.0.0
```

## Source

This reference is derived from
[Keep a Changelog v1.1.0](https://keepachangelog.com/en/1.1.0/) by Olivier
Lacan, licensed under [Creative Commons](https://creativecommons.org/licenses/by/3.0/).
