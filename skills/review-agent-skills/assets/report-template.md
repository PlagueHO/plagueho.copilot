# Agent Skill Review

## Scope

- Targets: {{explicit supplied paths and resolved skills}}
- Review mode: {{full / frontmatter-only; record the explicit user limit for frontmatter-only mode}}
- Review status: {{✅ complete / ⚠️ incomplete / 🚫 blocked}}
- Policies: {{standard, selected local policy and source, quality}}
- Method: {{checker version/command, direct measurements, judgment, source checks}}
- Boundary: Read-only static review. Target scripts were not executed.

## Summary and score

{{State the main result and highest-impact fix. Mark blocked or incomplete work plainly.}}

{{For a full review, state the expected catalog rule count, accounted-for count, and any unverified count. For frontmatter-only mode, label the result limited and name the excluded rule groups.}}

Use these display labels in status cells: **✅ PASS**, **❌ FAIL**, **⏳ NOT_CHECKED**, and **➖ NOT_APPLICABLE (N/A)**. For detection rules use **✅ NONE_DETECTED** and **🔎 DETECTED (confirmed)** or **🔎 DETECTED (possible)**. Keep the text beside each emoji. Keep checker JSON states unchanged.

| Skill | Basis | ✅ Passed | ❌ Failed | ⏳ Not checked | ➖ Not applicable | Score | Coverage |
|---|---|---|---|---|---|---|---|
| {{skill}} | {{standard / local / quality}} | {{count}} | {{count}} | {{count}} | {{count}} | {{0-100 / no score; provisional if incomplete}} | {{completed / applicable}} |

Score = 100 * passed / completed applicable checks. Count each rule once per skill. Exclude not-applicable checks and detection rules. Show no score when no checks complete. Scores describe this rubric, not measured runtime reliability. Label frontmatter-only scores as selected-check scores, not full-review scores.

Detection: {{count}} 🔎 detected ({{count}} confirmed, {{count}} possible), {{count}} ✅ none detected, {{count}} ⏳ not checked. Detection results are outside the score. `NONE_DETECTED` is not proof that no issue exists.

## Token budget and size warnings

{{For each skill in a full review, fill this table using the token-budget policy. For explicit frontmatter-only mode, state outside scope without reading excluded content.}}

| Skill | Measure | Characters | Tokens or labeled estimate | Body lines | Included files and load conditions |
|---|---|---|---|---|---|
| {{skill}} | Discovery metadata | {{count / unavailable}} | {{count / estimate / unavailable}} | N/A | {{decoded name and description; host wrappers excluded}} |
| {{skill}} | Body | {{count / unavailable}} | {{count / estimate / unavailable}} | {{count / uncertain}} | {{body boundaries}} |
| {{skill}} | Full entry file | {{count / unavailable}} | {{count / estimate / unavailable}} | N/A | {{host behavior / conservative whole-file assumption}} |
| {{skill}} | Required load | {{count / known subtotal}} | {{count / estimate / unavailable}} | N/A | {{entry plus unique mandatory text resources; unresolved paths}} |
| {{skill}} | Conditional loads | {{counts by branch / none}} | {{counts by branch / estimates / unavailable}} | N/A | {{named branches and unique additional paths}} |
| {{skill}} | Package text inventory | {{count / partial}} | {{count / estimate / unavailable}} | N/A | {{inclusions, exclusions, and unreadable files; not runtime usage}} |

Counting basis: {{local tokenizer/model or encoding, version, method, scope, and limits; or rough estimate formula and missing tokenizer}}. Use the same counting basis for totals. Do not upload content or install a tokenizer automatically.

Size status: {{✅ within recommended size / ⚠️ size warning / ⚠️ estimated-size warning / ⏳ unverified}}. Call out a body at or above 5,000 tokens or 500 physical body lines. Also flag a required load at or above 5,000 tokens as the review's quality policy. These are not format failures or proof of poor performance.

Largest contributors: {{file/section locations, counts, and mandatory/conditional status}}. Reduction guidance: {{specific cuts, conditional references, or fixed checks suitable for scripts; preserve safety and needed domain facts}}.

Keep rough token estimates unverified under TK-007 unless a suitable measured subtotal already establishes a failure. Record the blocker and next action. Use BP-003 for the line verdict; do not count line size again under TK-007. Do not fail TK-001 or TK-002 from size alone.

Static token size is not actual task usage or cost. Required and conditional loads are distinct from package inventory. Tool output, generated text, repeated calls, caching, and model billing are not measured here.

## Findings by category and severity

Repeat the heading and table for each affected category. Sort critical, high, medium, then low. Say "No findings" when there are none; do not invent findings to fill the template.

### {{Category}} / {{Severity}}

| Rule ID | Basis | Skill | Location (file:line-line) | Evidence | Impact | Fix guidance |
|---|---|---|---|---|---|---|
| {{ID}} | {{standard / local / quality}} | {{skill}} | {{relative path and one-based lines}} | {{short redacted evidence}} | {{specific effect}} | {{actionable fix}} |

## Cross-skill review

{{For one skill, state NOT_APPLICABLE. For a collection, complete all three rows and cite every affected skill. Keep this score separate from per-skill scores.}}

| Rule ID | Category | State | Locations and evidence | Fix guidance |
|---|---|---|---|---|
| XS-001 | Consistency | {{display state}} | {{conflicting instructions or evidence of agreement}} | {{fix / none}} |
| XS-002 | Shared knowledge | {{display state}} | {{repeated rules and authority}} | {{fix / none}} |
| XS-003 | Overlap | {{display state}} | {{competing triggers and example request}} | {{fix / none}} |

Collection score: {{score / no score / ➖ NOT_APPLICABLE (N/A)}}. Coverage: {{completed / applicable}}.

## Check ledger

For a full review, include every rule ID from the catalog in its proper scope, including clean checks and reasoned exclusions. For explicitly requested frontmatter-only mode, include the selected checker rules and state the excluded groups in Scope. This ledger supports the counts above.

| Skill or collection | Rule ID | Basis | State | Evidence or reason |
|---|---|---|---|---|
| {{scope}} | {{ID}} | {{basis}} | {{display state}} | {{measurement, inspected location, source, or blocker}} |

Completion gate: {{confirm that ledger IDs match the catalog, no available applicable check remains unattempted, and summary counts reconcile; for a limited review, confirm the explicit user limit instead}}

## Limits and next actions

{{For each NOT_CHECKED rule, state its specific blocker, the safe method attempted or why no method was allowed, and the next action. Do not use a checker failure as a blanket blocker for independent checks. Mark verification incomplete when any applicable rule remains NOT_CHECKED.}}

{{List unavailable files, dependencies, or external facts. For a blocked request with no target, show no score and ask for an explicit skill path, list, or collection folder.}}

{{List prioritized fixes without changing target files. Distinguish observed facts from suggestions. State which runtime or activation evaluations were not performed.}}
