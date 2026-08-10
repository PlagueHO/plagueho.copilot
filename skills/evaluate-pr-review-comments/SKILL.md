---
name: evaluate-pr-review-comments
description: "**WORKFLOW SKILL** — Evaluates review comments on a GitHub Pull Request, classifying each by validity, category, impact, and risk, then recommends whether to apply, consider, or skip. WHEN: \"evaluate PR comments\", \"review PR feedback\", \"triage review comments\", \"evaluate PR reviews\", \"PR comment evaluation\", \"should I apply this review comment\". INVOKES: GitHub PR read tools, file reading tools. FOR SINGLE OPERATIONS: read individual PR review comments via GitHub MCP tools directly."
argument-hint: 'Optionally provide the PR number to review (e.g., 42)'
---

# Evaluate PR Review Comments

Evaluate review comments on a Pull Request, classifying each for validity and
recommending actions. Produces a structured assessment report with per-comment
analysis and an overall summary.

## Prerequisites

- **Required MCP tools:** `github` (pull request read access)
- **Required permissions:** Read access to the repository codebase
- **Enable MCP:** Run `/mcp add github` if not enabled

## MCP Tools Used

| Step | Tool | Method | Purpose |
|------|------|--------|---------|
| 1 | `github` | `get_pull_request` | Load PR details |
| 2 | `github` | `get_pull_request_diff` | Retrieve full diff |
| 2 | `github` | `get_pull_request_files` | List changed files |
| 2 | `github` | `get_pull_request_reviews` | Retrieve submitted reviews |
| 2 | `github` | `get_pull_request_review_comments` | Retrieve threaded review comments |
| 2 | `github` | `get_pull_request_comments` | Retrieve non-review comments |

**CLI Fallback (if MCP unavailable):**

```bash
gh pr view <number> --json title,body,author
gh pr diff <number>
gh pr view <number> --json files
gh api repos/{owner}/{repo}/pulls/<number>/reviews
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

## Process

### Step 1 — Determine the PR

1. If a PR number was provided as an argument, use it.
2. Otherwise, check the current Git branch and find an open PR for it
   using the GitHub repository tool.
3. If no PR can be determined, ask the user:
   *"Which PR number should I review comments for?"*

### Step 2 — Retrieve PR Context

Use the GitHub Pull Request read tool to gather:

1. **PR details** (method: `get`) — title, description, author, intent.
2. **Diff** (method: `get_diff`) — full changeset.
3. **Changed files** (method: `get_files`) — files modified in the PR.
4. **Reviews** (method: `get_reviews`) — submitted reviews and verdicts.
5. **Review comments** (method: `get_review_comments`) — threaded comments
   with resolution status. Paginate with `perPage: 100` using the `after`
   cursor until all comments are retrieved.
6. **PR comments** (method: `get_comments`) — non-review discussion comments.

### Step 3 — Analyze Each Review Comment

For each comment or thread, perform three sub-steps:

#### 3a. Understand the Comment

- What is the reviewer asking or suggesting?
- Does it reference a specific line, file, or pattern?
- Is it a question, suggestion, nitpick, or blocking concern?

#### 3b. Validate Against the Codebase

- Read the relevant file(s) for full context around the commented code.
- Assess whether the observation is factually correct.
- Check alignment with project coding conventions, patterns, and architecture.

#### 3c. Classify and Assess

For each comment, determine the following attributes:

| Attribute | Values |
|---|---|
| **Validity** | Valid / Partially Valid / Invalid |
| **Category** | Bug, Security, Performance, Style, Readability, Architecture, Nitpick, Question, or Praise |
| **Recommendation** | Apply / Consider / Skip |
| **Difficulty** | Trivial / Easy / Moderate / Hard |
| **Impact** | Breaking / Significant / Minor / Cosmetic |
| **Risk** | Regression risk if applied: Low / Medium / High |

### Step 4 — Generate the Assessment Report

Produce the report using the template in `assets/report-template.md`. The
report contains four sections:

1. **Summary** — totals, breakdowns by recommendation and category, overall
   review quality.
2. **Detailed Assessment Table** — one row per comment with all classification
   attributes.
3. **Detailed Analysis** — for each Apply or Consider comment: quote, context,
   analysis, recommendation, and implementation notes.
4. **Comments Recommended to Skip** — for each Skip comment: reason for
   skipping (e.g., stylistic preference, incorrect observation, already
   addressed).

## Edge Cases

- **No review comments found**: Report that no comments exist and stop.
- **Resolved threads**: Include in the assessment with resolved status noted.
- **Ambiguous comments**: Flag as ambiguous, provide best interpretation, and
  note the uncertainty.
- **Large PRs**: If the diff is very large, focus on changed files referenced
  by review comments rather than reading the entire diff.

## Validation

After generating the report, verify:

- [ ] Every review comment is accounted for in the assessment table
- [ ] Each Apply/Consider comment has a detailed analysis entry
- [ ] Each Skip comment has a documented reason
- [ ] Summary totals match the number of rows in the assessment table
- [ ] Categories and recommendations are from the defined value sets

## Guidelines

- **Be objective** — base assessments on code quality, conventions, and
  correctness, not on authorship.
- **Consider project context** — reference existing codebase patterns when
  evaluating suggestions.
- **Prioritize safety** — always recommend applying security and correctness
  concerns.
- **Flag ambiguity** — if a comment is unclear, note this and provide the best
  interpretation.
- **Include resolved threads** — note resolved status but include in the
  assessment for completeness.
