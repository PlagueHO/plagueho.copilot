# Approaches Category Template

Reference template for reviewing documents in the `approaches/` subfolder
of `/docs/guide/multitenant/`.

## Document Purpose

Approaches documents describe **architectural patterns and strategies** for
a service category in a multitenant context. They explain **what is unique
about multitenancy** for the category and present the **isolation spectrum**
(shared → semi-isolated → dedicated) with tradeoffs. Azure services are
used illustratively — detailed service configuration belongs in the
Service-Specific articles.

## Required Structure

Documents follow this section order:

1. **Introduction** — Why multitenancy matters for this service category.
   Sets scope and audience.
2. **Key considerations and requirements** — Domain-appropriate
   subsections covering the factors an architect must weigh. Subsections
   vary by topic (see examples below). Each should explain what is
   different in a multitenant context.
3. **Approaches and patterns to consider** — Named patterns or strategies,
   each describing the approach, tradeoffs, and when to use it. Some
   patterns include formal Benefits/Risks subsections; others use inline
   tradeoff discussion. Either is acceptable.
4. **Antipatterns to avoid** — Common mistakes with explanations of why
   they are problematic in a multitenant context.
5. **Contributors** — Attribution with LinkedIn links.
6. **Next steps / Related resources** — Links to related content
   (Considerations, Service-Specific, WAF, Cloud Design Patterns).

## Key Considerations — Topic-Appropriate Subsections

Subsections are **not fixed** — they depend on the service category.
Common subsections observed across current approaches documents include:

| Category | Typical Key Considerations |
|----------|---------------------------|
| Resource organization | Tenant isolation requirements, Scale |
| Governance and compliance | Resource isolation, Data management, Sovereignty, Compliance requirements |
| Cost management | Purpose of measurement, Shared components |
| Deployment and configuration | Expected scale, Onboarding steps, Automation, Resource management responsibility |
| Compute | Scale, State, Isolation |
| Control planes | *(goes directly to approaches)* |
| Networking | Infrastructure vs. platform services, Subnet sizing, Public/private access |
| Storage and data | Scale, Performance predictability, Data isolation, Complexity, Cost |
| Messaging | Scale, Performance predictability and reliability, Management complexity, Cost |
| Identity | Authentication, Authorization |
| Integration | Data flow direction, Access models, Real-time vs. batch, Data formats |
| AI and machine learning | Tenant isolation, Scalability, Performance, Implementation complexity, Cost |

The review should assess whether the chosen subsections are appropriate
for the topic, not whether they match a fixed list.

## Example Headings

```markdown
# Architectural approaches for [category] in multitenant solutions

## Key considerations and requirements

### [Topic-appropriate subsection 1]

### [Topic-appropriate subsection 2]

## Approaches and patterns to consider

### [Pattern name]

## Antipatterns to avoid

## Contributors

## Next steps
```

## Style Rules

- Use "you" to address the reader.
- Use Azure service names illustratively (e.g., "for example, in
  Azure SQL Database..."), not as the primary subject — the pattern
  is the subject.
- Use "tenant" instead of "customer" when referring to tenants.
- Diagram alt-text follows `Diagram that shows...` pattern.
- Reference the noisy neighbor problem explicitly for shared resources.
- Cross-link to related Considerations and Service-Specific guidance.

## Multitenancy Principles

Every approaches document should address relevant principles:

- **Isolation spectrum:** Always a continuum with tradeoffs, never binary.
- **Noisy neighbor:** Central challenge for shared resources — reference
  explicitly and link to the antipattern.
- **Tenant lifecycle:** Cover onboarding, scaling, migration, offboarding
  where applicable.
- **Cost allocation:** Measurement challenges for shared resources;
  link to consumption guidance.
- **Bin packing and scale-out:** How to grow across resources, resource
  groups, and subscriptions.
- **Deployment Stamps:** Cross-cutting scaling strategy — reference where
  applicable.
- **Dual focus:** Address both technical and commercial/operational
  decisions.

Not every principle applies to every document — evaluate based on the
service category.
