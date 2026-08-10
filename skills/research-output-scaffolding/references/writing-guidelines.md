# Writing Guidelines

Quality and style expectations for research output sections.

## Voice and Tone

- **Technical and precise** — use exact service names, API names, parameters
- **Active voice** — "Container Apps scales horizontally" not "horizontal
  scaling is performed"
- **Present tense** — describe current capabilities, not future promises
- **Direct** — no hedging phrases like "it should be noted that"

## Structure

### Section Length Targets

| Purpose | Average Section | Maximum Section |
|---------|----------------|-----------------|
| deep-guide | 800-1500 words | 2500 words |
| presentation | 200-400 words | 600 words |
| lab | 400-800 words | 1200 words |
| demo | 300-600 words | 1000 words |

### Heading Hierarchy

- `# Section Title` — only one per file (matches frontmatter title)
- `## Major Subsection` — main structural divisions
- `### Detail` — specific topics within a subsection
- Never skip levels (no `#` → `###`)

### Code Examples

- Every code block must have a language identifier
- Include comments explaining non-obvious lines
- Show complete working snippets where possible (not fragments)
- For long examples, use collapsible `<details>` blocks

## Attribution

- Every factual claim must be traceable to a research note
- Use inline links to source documentation: `[feature](url)`
- For disputed or uncertain claims, add a footnote with sources
- Do not present inferred conclusions as documented facts

## Cross-References

- Link between output sections when concepts span sections
- Use relative links: `[Architecture](./02-architecture.md)`
- Mention related dimensions explicitly: "See also: Security considerations
  in [Security](./05-security.md)"

## Completeness Checklist

Before marking a section as `complete`:

- [ ] All primary area notes have been synthesized
- [ ] Secondary area notes have been reviewed for additions
- [ ] Code examples are present where applicable
- [ ] Limitations and caveats are explicitly stated
- [ ] Source links are valid and current
- [ ] Section length is within target range
- [ ] No TODO or placeholder text remains
