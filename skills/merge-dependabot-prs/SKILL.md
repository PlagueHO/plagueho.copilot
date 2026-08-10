---
name: merge-dependabot-prs
description: "**WORKFLOW SKILL** — Approve and squash-merge all open Dependabot PRs in parallel, requesting rebase for conflicts and triaging failures. WHEN: \"merge dependabot PRs\", \"auto-merge dependabot\", \"process dependabot updates\", \"bulk merge dependabot\", \"dependabot batch merge\", \"dependabot sweep\", \"approve dependabot PRs\". INVOKES: runSubagent for parallel processing, GitHub MCP tools. FOR SINGLE OPERATIONS: use GitHub MCP directly."
argument-hint: 'Optionally provide owner/repo (e.g., PlagueHO/plagueho.copilot). Defaults to the current repository.'
---

# Merge Dependabot PRs

Merge all open Dependabot pull requests in a repository in parallel. Each PR
is evaluated for build status and merge conflicts, then handled according to
its state. Produces a structured status report at the end.

## Prerequisites

- **Required MCP tools:** `github` (pull request read/write access)
- **Required permissions:** Write access to the repository (merge, review, comment)
- **Enable MCP:** Run `/mcp add github` if not enabled

## MCP Tools Used

| Step | Tool | Method | Purpose |
|------|------|--------|---------|
| 1 | `github` | `list_pull_requests` | Find open Dependabot PRs |
| 2 | `github` | `get_pull_request` | Load PR details and mergeable state |
| 2 | `github` | `get_pull_request_status` | Check CI/check suite status |
| 2 | `github` | `get_pull_request_files` | List changed files for review |
| 3a | `github` | `create_pull_request_review` | Submit approval review |
| 3a | `github` | `add_issue_comment` | Comment `:lgtm:` on the PR |
| 3a | `github` | `merge_pull_request` | Squash merge the PR |
| 3b | `github` | `add_issue_comment` | Comment `@dependabot rebase` |
| 3c | `github` | `add_issue_comment` | Comment with failure triage |

**CLI Fallback (if MCP unavailable):**

```bash
gh pr list --author "app/dependabot" --state open --json number,title,mergeable,statusCheckRollup
gh pr view <number> --json mergeable,statusCheckRollup,files
gh pr review <number> --approve
gh pr comment <number> --body ":lgtm:"
gh pr merge <number> --squash
gh pr comment <number> --body "@dependabot rebase"
```

## Process

### Step 1 — Discover Dependabot PRs

1. Determine the target repository:
   - If an `owner/repo` argument was provided, use it.
   - Otherwise, detect the current repository from the workspace Git remote.
   - If neither works, ask: *"Which repository should I process? (owner/repo)"*

2. List all open pull requests authored by `app/dependabot` or
   `dependabot[bot]`:

   ```text
   list_pull_requests(owner, repo, state: "open")
   ```

   Filter the results to only PRs where the author login is `dependabot[bot]`
   or the user type is `Bot` with the name containing `dependabot`.

3. If no Dependabot PRs are found, report that there are no open Dependabot
   PRs and stop.

4. Display the list of discovered PRs to the user before proceeding:
   *"Found N open Dependabot PRs. Processing in parallel..."*

### Step 2 — Evaluate Each PR (Parallel)

Launch a `runSubagent` (or `/fleet` in Copilot CLI) for **each** Dependabot
PR to evaluate it in parallel. Each subagent performs the following for its
assigned PR:

#### 2a. Retrieve PR State

Load the PR details to determine:

- **Mergeable state**: Is the PR mergeable, conflicting, or unknown?
- **CI status**: Are all required status checks passing?

Use `get_pull_request` to get the `mergeable` field and
`get_pull_request_status` (or the `statusCheckRollup` field) to determine CI
outcome.

#### 2b. Classify the PR

Based on the retrieved state, classify into one of three categories:

| CI Status | Merge Conflicts | Classification |
|-----------|-----------------|----------------|
| Passing | None | **ready-to-merge** |
| Passing | Has conflicts | **needs-rebase** |
| Failing | Any | **build-failing** |
| Pending | Any | **ci-pending** |

### Step 3 — Act on Each PR (Parallel)

Each subagent acts on its PR based on the classification from Step 2:

#### 3a. Ready to Merge (build passing, no conflicts)

1. **Get the list of changed files** using `get_pull_request_files`.
2. **Submit an approving review** using `create_pull_request_review` with:
   - `event: "APPROVE"`
   - Mark all files as reviewed in the review body.
3. **Add a comment** `:lgtm:` using `add_issue_comment`.
4. **Squash merge** the PR using `merge_pull_request` with:
   - `merge_method: "squash"`

Record result: `merged`.

#### 3b. Needs Rebase (build passing, merge conflicts)

1. **Add a comment** `@dependabot rebase` using `add_issue_comment`.
   This triggers Dependabot to rebase the PR and resolve conflicts.
2. Do **not** attempt to merge.

Record result: `rebase-requested`.

Report to the user: *"PR #N has merge conflicts. Commented @dependabot rebase.
Wait approximately 5 minutes for Dependabot to rebase, then run this skill
again to merge."*

#### 3c. Build Failing

1. **Retrieve the failing check details** from the status checks or check
   runs to identify which checks failed and why.
2. **Triage the failure**:
   - Read the PR title to identify the dependency and version bump.
   - Determine if the failure is likely caused by a breaking change in the
     dependency, a flaky test, or an infrastructure issue.
   - If possible, identify the specific failing test or build step.
3. **Add a comment** to the PR summarizing the failure and triage analysis.
4. Do **not** attempt to merge.

Record result: `build-failing` with triage details.

#### 3d. CI Pending

1. Do **not** act on the PR — checks are still running.
2. Record result: `ci-pending`.

Report to the user: *"PR #N has CI checks still running. Run this skill again
once checks complete."*

### Step 4 — Generate Status Report

After all subagents complete, compile the results into a status report using
the template in `assets/report-template.md`.

The report includes:

1. **Summary** — total PRs processed, counts by outcome.
2. **PR Status Table** — one row per PR with number, title, dependency,
   classification, action taken, and result.
3. **Build Failures** — detailed triage for each failing PR.
4. **Next Steps** — actionable guidance for remaining items.

Present the report to the user.

## Edge Cases

- **No Dependabot PRs**: Report that none were found and stop.
- **Merge fails after approval**: Record the error, report it in the status
  table, and continue processing other PRs.
- **Rate limiting**: If GitHub API rate limits are hit, pause and report the
  remaining PRs that were not processed.
- **Branch protection rules**: If squash merge is blocked by branch protection,
  report the specific protection rule blocking the merge.
- **Stale PR (unknown mergeable state)**: GitHub sometimes returns `UNKNOWN`
  for the mergeable state. Treat this as needs-rebase and comment
  `@dependabot rebase`.
- **Large number of PRs**: If there are more than 20 Dependabot PRs, process
  them in batches of 10 to avoid overwhelming the API.

## Validation

After completing the process, verify:

- [ ] Every discovered Dependabot PR appears in the status report
- [ ] All merged PRs were squash merged (not regular or rebase merge)
- [ ] All merged PRs received an approving review and `:lgtm:` comment
- [ ] All conflict PRs received a `@dependabot rebase` comment
- [ ] All failing PRs have triage details in the report
- [ ] Summary counts match the rows in the status table

## Guidelines

- **Never force merge** — if a PR cannot be cleanly squash merged, do not
  bypass protections.
- **Preserve commit history** — always use squash merge to keep the main
  branch clean.
- **Be idempotent** — running the skill multiple times is safe. Already-merged
  PRs will not appear in the open PR list.
- **Respect CI** — never merge a PR with failing or pending checks.
- **Batch awareness** — after requesting rebases, advise the user to wait
  ~5 minutes before running the skill again so Dependabot can complete the
  rebase operations.
