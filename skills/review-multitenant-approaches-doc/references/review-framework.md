# Multitenancy Approaches Review Framework

Use during Step 4 of the review process. Defines the **architectural dimensions** that any approaches document — existing or future — should address for its technology category.

Approaches documents describe non-functional design patterns and architectural trade-offs for multitenant solutions. They bridge **business requirements** (considerations) and **technology implementation** (service-specific guidance). This framework evaluates whether a document fulfils that bridging role.

> **Principle:** Do not review an approaches document against a catalogue of its own content. Evaluate whether the approaches it presents are **clear, technically sound, and strategically relevant** to architects making multitenant design decisions.

## How to Use This Framework

1. Identify which **architectural dimensions** (below) are relevant to the document's technology category.
2. For each relevant dimension, ask the **review questions**.
3. Flag issues using the **red flags** list.
4. Apply the **cross-cutting evaluation criteria** (Section B) to every document regardless of category.
5. Record findings using the severity and confidence scales defined in the SKILL.

Not every dimension applies to every document — use judgement based on the technology category. A networking approaches document may have limited relevance to "Customization and Tenant Experience", while an AI/ML document may not deeply address "Resource Topology and Organization".

## A. Architectural Dimensions

Each dimension covers a fundamental area of multitenant system design. Approaches documents should present patterns and trade-offs within these dimensions, not just describe Azure features.

### 1. Isolation and Sharing

The core multitenancy trade-off: how resources, data, and workloads are shared or separated across tenants.

**Review questions:**

- Does the document present isolation as a **spectrum** (fully shared → semi-isolated → fully dedicated) with trade-offs at each point — not a binary choice?
- Are the **dimensions of isolation** relevant to the category made explicit (e.g., compute isolation, data isolation, network isolation, logical isolation)?
- Does it explain what **isolation means** in this technology context — what is separated, what is shared, and where the boundary sits?
- Are the **trade-offs honest** — cost, complexity, operational overhead, performance — rather than implying one point on the spectrum is always correct?

**Red flags:**

- Binary framing (shared OR dedicated) with no middle ground.
- Isolation described only in terms of Azure resource boundaries without explaining architectural implications.
- No discussion of what tenants gain or lose at different isolation points.

### 2. Scale, Capacity, and Density

How the architecture scales as tenant count grows and how capacity is managed across tenants.

**Review questions:**

- Does the document explain how the approach scales with **tenant count** and **per-tenant load** independently?
- Are **platform and service limits** acknowledged as constraints that affect tenant density and force scale-out decisions?
- Is the **bin-packing vs. dedicated allocation** trade-off addressed — density optimization versus isolation and predictability?
- Does it discuss **horizontal scale-out strategies** (e.g., Deployment Stamps, sharding, partitioning) and when they become necessary?
- Are **capacity planning considerations** specific to multitenancy addressed — not just general autoscaling guidance?

**Red flags:**

- Scaling advice that applies equally to single-tenant systems with no multitenant-specific nuance.
- Ignoring platform limits that constrain tenant density.
- No guidance on when to scale out (add units) versus scale up (increase capacity of existing units).

### 3. Performance Predictability and Fairness

Ensuring tenants receive consistent, fair performance regardless of other tenants' activity.

**Review questions:**

- Is the **noisy neighbor** problem addressed — how one tenant's workload can degrade another's experience?
- Does the document present **mitigation strategies** (resource quotas, rate limiting, throttling, queue-based leveling) rather than just naming the problem?
- Are **per-tenant SLA or QoS differentiation** patterns discussed — premium tenants getting dedicated or prioritized resources?
- Does it explain how to **measure and attribute** performance at the tenant level?

**Red flags:**

- Shared-resource patterns with no noisy-neighbor discussion.
- Performance guidance that is generic (e.g., "use caching") without explaining what changes in a multitenant context.
- No mention of fairness or resource-sharing policies.

### 4. Cost Efficiency and Attribution

How to operate the solution cost-effectively while attributing costs to individual tenants for commercial viability.

**Review questions:**

- Does the document explain how the approach affects **per-tenant unit economics** — the relationship between infrastructure cost and tenant revenue?
- Is **cost attribution** addressed — how to measure or apportion costs for shared resources?
- Are the **cost trade-offs of isolation** made explicit — more isolation generally costs more?
- Does it discuss **commercial model alignment** — how architectural choices enable or constrain pricing models (per-tenant, usage-based, tiered)?

**Red flags:**

- Approaches presented without any cost context.
- Shared-resource patterns with no discussion of cost attribution difficulty.
- Dedicated-resource patterns without acknowledging the cost implications at scale.

### 5. Tenant Lifecycle Management

How tenants are onboarded, configured, scaled, migrated, and offboarded — and how the approach supports or complicates each phase.

**Review questions:**

- Does the document explain how the approach affects **tenant onboarding** — what must be provisioned, configured, or allocated when a new tenant is added?
- Is **tenant offboarding** addressed — resource cleanup, data retention, and deprovisioning?
- Does it cover **tenant migration** between isolation levels (e.g., moving a growing tenant from shared to dedicated resources)?
- Are **automation requirements** discussed — what must be automated for the approach to work at scale?

**Red flags:**

- Approaches that implicitly require manual intervention for each new tenant without acknowledging the scaling limitation.
- No consideration of what happens when a tenant leaves.
- No discussion of how tenants move between tiers or approaches as needs change.

### 6. Security Boundaries and Trust

How the architecture enforces security boundaries between tenants and prevents cross-tenant access.

**Review questions:**

- Does the document clearly define the **trust boundary** for each approach — where tenant data and operations are separated?
- Are **cross-tenant access risks** specific to the technology category identified and mitigated?
- Does it explain the **strength of the isolation mechanism** — is it a logical boundary (code/config), a platform boundary (resource-level), or an infrastructure boundary (network/subscription)?
- Are **authentication and authorization** patterns included where the approach involves tenant-facing access?

**Red flags:**

- Shared-resource patterns with no discussion of cross-tenant access risk.
- Conflating management boundaries with security boundaries.
- No guidance on tenant-context propagation through the technology layer.

### 7. Compliance, Governance, and Data Sovereignty

How the architecture meets regulatory, compliance, and data residency requirements that may differ per tenant.

**Review questions:**

- Does the document address how the approach supports tenants with **different compliance requirements** sharing the same system?
- Is **data sovereignty** discussed — per-tenant geographic placement of resources or data?
- Are **governance patterns** (policy enforcement, audit logging, access control) presented as part of the approach?
- Does it explain how **compliance evidence** (audit trails, logs, certifications) can be provided per tenant?

**Red flags:**

- Assuming all tenants share the same compliance requirements.
- No discussion of data residency when the approach involves data storage or processing.
- Governance treated as an afterthought rather than an architectural constraint.

### 8. Operational Complexity and Manageability

The operational burden of running the approach at scale across many tenants.

**Review questions:**

- Does the document acknowledge the **operational trade-offs** of each approach — more isolation often means more operational overhead?
- Is **per-tenant observability** addressed — monitoring, alerting, and diagnostics scoped to individual tenants?
- Does it discuss **update and maintenance strategies** — how changes are rolled out across tenants (e.g., progressive rollout, ring-based deployment)?
- Are **failure blast radius** implications discussed — how a failure in shared infrastructure affects multiple tenants?

**Red flags:**

- Patterns presented without acknowledging operational cost at scale.
- No discussion of how to monitor or troubleshoot per-tenant issues.
- Ignoring blast radius — shared resources failing with no discussion of tenant impact.

### 9. Routing, Discovery, and Tenant Context

How the system identifies, routes, and contextualizes tenant requests through the technology layer.

**Review questions:**

- Does the document explain how **tenant context is established** and propagated through the approach (e.g., tenant ID in tokens, headers, partition keys, connection strings)?
- Are **routing strategies** discussed — how requests or data reach the correct tenant's resources?
- Is the **tenant catalog or mapping** concept addressed — how the system knows which resources belong to which tenant?
- Does it cover **custom domain or endpoint** patterns where tenants need their own entry points?

**Red flags:**

- Approaches that assume tenant context is "just there" without explaining how it's established.
- No discussion of routing when the approach involves shared infrastructure.
- Missing tenant-to-resource mapping for dedicated-resource patterns.

### 10. Customization and Tenant Experience

How the approach supports per-tenant configuration, feature variation, and experience differentiation.

**Review questions:**

- Does the document address how the approach supports **per-tenant configuration** — feature flags, tier-based capabilities, or tenant-specific parameters?
- Is **tiered service delivery** discussed — how different tenants can receive different levels of capability or performance?
- Does it explain how **tenant-specific customization** interacts with the isolation model — dedicated resources enable more customization; shared resources constrain it?
- Are **self-service** versus **provider-managed** customization patterns distinguished?

**Red flags:**

- One-size-fits-all approaches with no acknowledgement of per-tenant variation.
- Customization discussed at the application layer only, without addressing infrastructure-level implications.

### 11. Resilience, Continuity, and Tenant Recovery

How the architecture handles failures and ensures business continuity for individual tenants.

**Review questions:**

- Does the document explain how the approach affects **fault isolation** between tenants — does a failure in one tenant's workload affect others?
- Are **per-tenant recovery** patterns discussed — backup, restore, and disaster recovery scoped to individual tenants?
- Does it address **blast radius** — the scope of impact when shared resources fail?
- Are **graceful degradation** patterns discussed — how the system behaves when capacity is constrained?

**Red flags:**

- Shared-resource patterns with no discussion of blast radius.
- No per-tenant backup or recovery discussion when data is involved.
- DR strategy that treats all tenants as a monolith.

## B. Cross-Cutting Evaluation Criteria

Apply these criteria to **every** approaches document regardless of technology category.

### B1. Genuine Multitenant Value

Every approach must provide **unique value in a multitenant context** — not just repeat general Azure or cloud guidance.

- Does each pattern explain what is **different** when multiple tenants are involved versus a single-tenant deployment?
- Would the guidance be substantially the same for a single-tenant system? If yes, it lacks multitenant differentiation.
- Are **architectural trade-offs** framed in terms of tenant impact (cost per tenant, isolation per tenant, performance per tenant)?

### B2. Bridging Business and Technology

Approaches must connect architectural decisions to **business requirements and commercial considerations**.

- Does the document help an architect explain trade-offs to **business stakeholders** — not just technical teams?
- Are approaches linked back to the **considerations** they address (e.g., "this pattern supports tenants with different compliance requirements")?
- Does it acknowledge **commercial implications** — how a pattern affects pricing model, tenant acquisition cost, or operational margin?

### B3. Approaches vs. Considerations vs. Service-Specific Scope

- **Approaches** describe architectural patterns and strategies with trade-offs. They are technology-category scoped.
- **Considerations** describe cross-cutting concerns (pricing, tenancy models, mapping tenants to deployments).
- **Service-Specific** articles describe detailed configuration for individual Azure services.

Flag content in the wrong category:

- Detailed step-by-step service configuration → Service-Specific.
- Pricing model design or tenancy model selection → Considerations.
- General Azure best practices with no multitenancy angle → neither.

### B4. Terminology and Consistency

- "Tenant" used consistently — means the solution provider's customers or user groups, not Microsoft Entra tenants.
- Patterns described in terms of the **architectural approach** first, with Azure services as **illustrative examples** — not the other way around.
- Diagram alt-text follows `Diagram that shows...` pattern.

### B5. Cross-References and Context

- Does the document reference **related considerations** that drive the approaches?
- Does it reference **service-specific** articles for deeper implementation detail?
- Are **Well-Architected Framework** and **Cloud Design Pattern** links used where relevant?
- Is the **Deployment Stamps** pattern referenced where applicable as a cross-cutting scaling strategy?
- Is the **noisy neighbor antipattern** linked for shared-resource approaches?

### B6. Evolving Technology Areas

The approaches section must evolve to cover new technology categories as they become relevant to multitenant solutions.

When reviewing a document in a new or emerging area (e.g., Agentic AI, edge computing, confidential computing):

- Apply the same architectural dimensions above — they are technology-agnostic.
- Verify the document establishes what is **unique about multitenancy** in that technology area.
- Check that it doesn't assume the reader has existing approaches content for context — new-area documents must stand alone.
- Validate that patterns are grounded in **current platform capabilities** — use MCP tools to verify claims about new services or features.

## C. Applicability Guide

Use this table to assess which dimensions are most relevant to a given technology category. **●** = primary concern, **○** = typically relevant, blank = case-by-case.

| Dimension | Compute | Data | Networking | Identity | Messaging | Integration | AI/ML | Resource Org | Governance | Cost | Deployment | Control Planes |
|-----------|---------|------|------------|----------|-----------|-------------|-------|--------------|------------|------|------------|----------------|
| 1. Isolation and Sharing | ● | ● | ● | ● | ● | ○ | ● | ● | ○ | | | ○ |
| 2. Scale and Capacity | ● | ● | ○ | | ● | ○ | ● | ● | | | ○ | ● |
| 3. Performance and Fairness | ● | ● | ○ | | ● | ○ | ● | | | | | |
| 4. Cost and Attribution | ○ | ○ | ○ | | ○ | ○ | ● | ○ | | ● | | |
| 5. Tenant Lifecycle | ○ | ○ | ○ | ○ | | | | ○ | | | ● | ● |
| 6. Security Boundaries | ● | ● | ● | ● | ○ | ● | ○ | ○ | ● | | | ○ |
| 7. Compliance and Sovereignty | | ● | ○ | ○ | | ○ | ○ | ○ | ● | | | |
| 8. Operational Complexity | ● | ○ | ○ | | ○ | ○ | ○ | ○ | ○ | ○ | ● | ● |
| 9. Routing and Discovery | ● | ○ | ● | ● | ○ | ● | ○ | | | | | ● |
| 10. Customization | ○ | | | ● | | ○ | ● | | ○ | | ○ | ○ |
| 11. Resilience and Recovery | ○ | ● | ○ | | ○ | | ○ | | | | ○ | ○ |

This table is a starting guide — not a rigid rule. A specific document may emphasize dimensions differently based on its scope and audience.
