# Service-Specific Category Template

Reference template for reviewing documents in the `service/` subfolder of
`/docs/guide/multitenant/`.

## Required Structure

Documents in this category describe how a specific Azure service supports
multitenancy. They follow this section order:

1. **Introduction** — Service in a multitenant context.
2. **Features that support multitenancy** — Subsections for each feature.
3. **Isolation models** — With a comparison table.
4. **Service-specific considerations** — Unique guidance for the service.
5. **Contributors** — Attribution with LinkedIn links.
6. **Related resources / Next steps** — Links to related content.

## Example Headings

```markdown
# Multitenancy and [Service Name]

## Features that support multitenancy

### [Feature]

## Isolation models

### [Model]

#### Benefits

#### Trade-offs

## [Comparison table]

## Contributors

## Next steps
```

## Comparison Table Format

| Consideration | [Model 1] | [Model 2] | [Model 3] | Example scenario |
|---------------|-----------|-----------|-----------|------------------|
| Data isolation | ... | ... | ... | ... |
| Performance isolation | ... | ... | ... | ... |
| Deployment complexity | ... | ... | ... | ... |
| Operational complexity | ... | ... | ... | ... |
| Resource cost | ... | ... | ... | ... |

Columns: Consideration, one column per isolation model, Example scenario.

Rows (include where applicable): Data isolation, Performance isolation,
Deployment complexity, Operational complexity, Resource cost.

## Style Rules

- Lead with multitenancy-specific features of the service.
- Use consistent isolation terminology across all service docs.
- Link heavily to official Azure documentation for the service.
- Focus on "what" and "why", not "how" (implementation belongs elsewhere).
- Use callouts for warnings (`> [!WARNING]`).
- Keep code examples minimal — only include when illustrative.
- Use "you" to address the reader.
- Use "tenant" instead of "customer".
- Diagram alt-text follows `Diagram that shows...` pattern.
- Cross-link to related Approaches and Considerations guidance.

## Multitenancy Principles

- **Dual focus:** Address both technical and commercial decisions (pricing,
  SLAs, cost).
- **Noisy neighbor:** Central challenge — reference explicitly for shared
  resources; link to the antipattern.
- **Isolation spectrum:** Never binary; always a continuum with tradeoffs.
- **Tenant lifecycle:** Cover onboarding, migration, offboarding, schema
  updates.
- **Cost allocation:** Mention measurement challenges for shared resources;
  link to consumption guidance.
