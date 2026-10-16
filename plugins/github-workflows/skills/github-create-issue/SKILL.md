---
name: github-create-issue

description: >-
  Create clear GitHub issues with repository issue templates and
  ASD-STE100-aligned English. Use when asked to create an issue, choose a
  template, check for duplicates, or manage issue labels, assignees, milestones,
  and other maintainer details.

metadata:
  author: PlagueHO
  version: "1.0"
---

# GitHub Issue Maintainer

Create a useful GitHub issue that follows the target repository's issue forms
and uses clear, ASD-STE100-aligned English. Check for duplicate issues and
relevant metadata before creation. Show the complete issue and metadata for
approval before publishing it.

## Prerequisites

- Run commands from the target repository, or pass its full `OWNER/REPO` name
  to `gh`.
- Use the GitHub CLI (`gh`) and confirm access with `gh auth status`. Do not
  ask the user to share a password, token, or other credential.
- Create an issue only when the user asks to create one. A request to draft or
  review an issue does not authorize publication.

## Process

### 1. Confirm the target and intent

1. Identify the repository from the user's request or the current checkout.
   Confirm it with `gh repo view --json nameWithOwner --jq .nameWithOwner`.
2. Clarify missing information that changes the issue's purpose, category, or
   requested outcome. Do not invent facts, expected behavior, dates, or scope.
3. If the user asks only for a draft, prepare the draft and stop before
   creating or changing anything on GitHub.

### 2. Check for an existing issue

1. Search open and closed issues with distinctive words from the title and
   problem statement. For example:

   ```sh
   gh issue list --repo OWNER/REPO --state all --search "distinctive terms" --limit 100
   ```

2. Open likely matches and compare their scope and status.
3. If an issue already covers the same request, show it to the user. Ask
   whether to add information to that issue or create a separate one. Do not
   create a duplicate without approval.

### 3. Select and apply an issue template

1. Inspect `.github/ISSUE_TEMPLATE/`, `.github/ISSUE_TEMPLATE.md`, and any
   issue-template configuration file in the target repository.
2. Select the template that best matches the request. Preserve its section
   order, required fields, checklists, comments, and default labels.
3. For a YAML issue form, use its field labels and required fields to build the
   issue body. Keep the same field order and include every required field.
4. If no template exists, or no template fits, tell the user and recommend a
   suitable template to add. Do not create a repository file unless the user
   asks for that work. Ask whether to proceed with a clearly structured issue
   body instead.

### 4. Write the title and body in clear English

Use practical writing choices that align with ASD-STE100:

- Prefer short sentences, one main idea per sentence, and active voice.
- Use common, direct words and explicit actions. Avoid idioms, vague phrases,
  unnecessary jargon, and long noun phrases.
- State the problem or request, its effect, and the expected result when the
  user supplied those facts.
- Preserve the user's intent and all necessary technical terms, identifiers,
  code, commands, URLs, version numbers, and quoted evidence exactly.
- Do not add assumptions or rewrite technical terms to fit a word list.
- Keep the template's prompts and headings intact. Put each answer under the
  matching field.

ASD-STE100 is a copyrighted standard. Do not copy its dictionary or full rules
into this skill. Use an authorized copy of the current standard when available.
Without checking the current rules and approved dictionary, describe the
writing as **ASD-STE100-aligned**, not as certified or fully compliant. The
official maintenance-group site is <https://www.asd-ste100.org/>.

### 5. Check issue metadata

Inspect current repository labels and use the template's labels when they
exist. Add another existing label only when it clearly describes the issue.
Do not invent a label or create a repository label without the user's
approval. If a suitable label is missing, explain that and ask whether to add
it.

Set other metadata only when the user requests it or the choice is clear:

- **Assignee:** use the named GitHub login. Do not infer an assignee from a
  code owner, a similar issue, or a guess. Ask before assigning someone when
  the user did not specify them.
- **Milestone:** use an existing milestone only when its scope and timing
  clearly match the request. Do not create a milestone to file one issue.
- **Project, parent, blocking, or blocked-by links:** add them only when the
  user names them or confirms the proposed relation.
- **Issue type:** use an existing repository issue type only when it clearly
  fits and the CLI supports it.

Omit metadata that is not relevant. Never use a label, assignee, or milestone
as a substitute for missing issue details.

### 6. Preview and create

Before creating the issue, show the user:

- The repository and selected template.
- The proposed title and complete body.
- The labels, assignee, milestone, and any other metadata to apply.
- Any duplicate issue or missing template/label that affects the choice.

Ask the user to approve this exact issue and metadata. After approval, create
it with `gh issue create`, using `--repo`, `--title`, `--body` (or
`--body-file`), and only the approved metadata flags. Use the repository's
template content as the starting structure; do not omit required fields to
make a command shorter.

### 7. Verify and report

1. Confirm that the command returned an issue URL.
2. Read the created issue with `gh issue view` and verify its title, body,
   labels, assignee, and milestone.
3. Report the issue URL and the metadata that was applied. State clearly if
   any requested metadata could not be set.
4. If creation returns an error or an unclear result, search for the issue
   before retrying. This prevents duplicate creation after a partial success.

## Edge Cases

- **Authentication or permission failure:** report the exact failure and stop.
  Do not request credentials or claim that the issue was created.
- **Ambiguous template or category:** describe the viable choices and ask the
  user to choose before posting.
- **No suitable template or label:** recommend what to add and ask before
  creating repository configuration or taxonomy.
- **Possible duplicate:** show the matching issue and wait for the user's
  decision.
- **Missing facts:** leave optional information out or ask a focused question.
  Never fabricate reproduction steps, impact, operating system, or expected
  behavior.
- **Issue created but metadata failed:** report the issue URL and the failed
  metadata operation. Do not silently retry or create another issue.

## Example

For a request to report a reproducible bug:

1. Select the repository's bug template and preserve its required fields.
2. Write the report in direct language. Keep commands and error text exact.
3. Check for a matching issue and check the template's default label.
4. Show the title, filled template, label, and any proposed assignment.
5. Create and verify the issue only after the user approves the preview.
