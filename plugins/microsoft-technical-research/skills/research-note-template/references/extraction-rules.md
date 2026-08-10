# Extraction Rules

Rules governing how research notes are extracted from sources. All subagents
must follow these rules to ensure consistency across the research corpus.

## General Principles

1. **Attribute everything** — every fact, quote, or code snippet must link
   back to its source URL
2. **Prefer specifics over generalities** — extract concrete numbers, limits,
   configuration values, API names
3. **Preserve exact terminology** — use the same terms the source uses; do not
   paraphrase technical names
4. **Flag uncertainty** — if a source is ambiguous or contradictory, note it
   in the `questions_raised` section
5. **Date-stamp volatile claims** — anything that might change (pricing,
   preview features, limits) must include the source date

## What to Extract

### Always Extract

- Service limits, quotas, and constraints
- Configuration parameters and their default values
- Architecture component names and relationships
- API endpoint patterns and authentication requirements
- Pricing model structure (not necessarily exact numbers)
- Prerequisites and dependencies
- Code patterns showing SDK usage
- Exact error messages and their resolutions
- Feature availability by region, SKU, or tier

### Never Extract

- Marketing language without technical substance
- Repetitive content already captured in another note
- UI navigation instructions (unless relevant to a lab)
- Content behind authentication that cannot be verified
- Speculative roadmap items without official source

## Quality Thresholds

| Criterion | Minimum |
|-----------|---------|
| Key facts per note | 3 |
| Source attribution | Every fact must have a URL |
| Code snippets | Must include language identifier |
| Recency | Source must be dated within 18 months (flag older) |
| Relevance | Every fact must map to at least one plan dimension |

## Conflict Resolution

When two sources disagree:

1. Prefer official Microsoft documentation over blog posts
2. Prefer newer sources over older sources
3. Prefer architecture center over individual service docs for patterns
4. Note the conflict explicitly in `questions_raised`

## Code Snippet Rules

- Include the minimum viable snippet (not entire files)
- Add a comment indicating which SDK version the snippet targets
- Mark snippets as `verified` or `unverified` based on whether you can
  confirm they compile/run
- Always include the language identifier in the fenced code block
