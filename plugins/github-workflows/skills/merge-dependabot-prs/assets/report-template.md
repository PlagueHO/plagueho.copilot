# Dependabot PR Merge Status Report

## Summary

- **Repository**: `<owner>/<repo>`
- **Date**: <date>
- **Total Dependabot PRs found**: <count>
- **Breakdown by outcome**:
  - Merged: <count>
  - Rebase requested: <count>
  - Build failing: <count>
  - CI pending: <count>
  - Errors: <count>

## PR Status Table

| # | PR | Dependency | Version | Classification | Action | Result |
|---|-----|------------|---------|----------------|--------|--------|
| 1 | [#N](link) `PR title` | package-name | v1.0 → v2.0 | ready-to-merge | Approved, commented, squash merged | merged |
| 2 | [#N](link) `PR title` | package-name | v3.1 → v3.2 | needs-rebase | Commented `@dependabot rebase` | rebase-requested |
| 3 | [#N](link) `PR title` | package-name | v2.0 → v3.0 | build-failing | Triaged failure, commented | build-failing |
| 4 | [#N](link) `PR title` | package-name | v1.5 → v1.6 | ci-pending | No action (checks running) | ci-pending |

## Build Failures

For each PR with **build-failing** status:

### PR #N — `<PR title>`

- **Dependency**: `<package>` `<old version>` → `<new version>`
- **Failing checks**:
  - `<check name>`: <failure summary>
- **Triage**:
  - **Likely cause**: <breaking change in dependency / flaky test / infrastructure issue>
  - **Failing test or step**: `<test name or build step>`
  - **Recommended action**: <fix the breaking change / re-run CI / investigate>
- **Details**: <additional context or error messages>

## Next Steps

- **Rebased PRs**: Wait ~5 minutes for Dependabot to complete rebase operations, then run this skill again.
- **Failing PRs**: Review the triage details above and fix the underlying issues before merging.
- **Pending PRs**: Wait for CI checks to complete, then run this skill again.
