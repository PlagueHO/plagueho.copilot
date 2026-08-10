# Considerations Category Template

Reference template for reviewing documents in the `considerations/`
subfolder of `/docs/guide/multitenant/`.

## Purpose

Considerations documents help CTOs, lead architects, and product managers
of SaaS and ISV companies make strategic decisions about multitenancy.
They present **what to think about**, not how to implement.

## Required Structure

Documents follow this section order:

1. **Introduction** — Context, scope, and intended audience.
2. **Core decision-framework content** — Varies by topic. Must include:
   - Decision frameworks with options and tradeoffs.
   - Comparison tables where multiple options exist.
   - Benefits/Risks subsections for each option or model.
3. **Contributors** — Attribution with LinkedIn links.
4. **Next steps** — Links to related content.

## Key Characteristics

- Present decision frameworks, not implementation details.
- Balance technical and commercial/business perspectives.
- Use comparison tables to contrast options.
- Include Benefits/Risks subsections for each option.
- Use interrogative subheadings (questions that guide decisions).
- Use "consider" language — never prescriptive directives.
- Avoid code, configuration, or service-specific detail.
- Use conceptual diagrams (not implementation diagrams).

## Example Heading Structure

```markdown
# [Topic] for a multitenant solution

[Introduction — context, scope, audience]

## [Decision area — framed as a question or decision]

### [Option A]

#### Benefits

#### Risks

### [Option B]

#### Benefits

#### Risks

## [Second decision area]

[Comparison table if applicable]

## Contributors

## Next steps
```

## Topic Domains

The considerations section covers these topic domains. Each document
addresses one domain:

| Domain | Key Decisions |
|--------|---------------|
| Tenancy models | Tenant definition, isolation levels, deployment models |
| Tenant lifecycle | Trials, onboarding, scaling, moving, merge/split, offboarding |
| Pricing models | Revenue model, profitability, usage limits, pricing lifecycle |
| Control planes | Scope, responsibilities, reliability, multi-plane architecture |
| Consumption measurement | Metrics approach, estimation, cost attribution |
| Updates | Update policy, deployment strategy, customer communication |
| Request mapping | Tenant identification, routing, validation, performance |
| Identity | IdP selection, federation, authorization, workload identities |
| Domain names | Subdomain strategy, custom domains, DNS security, TLS |

## Style Rules

- Use "tenant" consistently (not "customer" when referring to tenants).
- Use "you" to address the reader.
- Maintain a balanced, consultative tone.
- Diagram alt-text follows `Diagram that shows...` pattern.
- Cross-link to related Considerations, Approaches, and Service-Specific
  guidance.

## Cross-Cutting Multitenancy Principles

Every considerations document should address these where relevant:

- **Isolation spectrum** — Isolation is a continuum, never binary.
- **Noisy neighbor** — The central challenge of shared resources;
  reference the antipattern explicitly.
- **Cost allocation** — Shared resources make per-tenant cost tracking
  difficult; acknowledge this challenge.
- **Tenant lifecycle** — Decisions affect onboarding, scaling, moving,
  and offboarding tenants.
- **Dual focus** — Both technical and commercial/business dimensions
  matter for every decision.
- **Tenant definition** — Clarify what a tenant means (B2B vs B2C,
  user vs organization vs group).
