# Multitenancy Considerations Review Framework

Use as a checklist when performing Step 4 of the review process. This framework defines fundamental concern areas — the non-functional requirements of a multitenant system — that apply across **any** architectural topic, whether it is an existing considerations document or a new one (e.g., Agentic AI, data platforms, edge computing).

For each concern area below, assess whether the document under review addresses it **where relevant to its topic**. Not every area applies to every document, but the reviewer should consciously evaluate applicability and note when an area is intentionally out of scope versus simply missing.

> **Goal:** Evaluate whether the document helps CTOs and lead architects think through the multitenancy implications of the topic — not whether it matches the content of other existing documents.

## How to Use This Framework

1. Read the document under review.
2. For each fundamental concern area, ask: *Does this topic have multitenancy implications in this area?*
3. If yes, evaluate whether the document surfaces the relevant decisions, tradeoffs, and risks.
4. If an area is not applicable, skip it — but record the reasoning in the review report.
5. Use the **Evaluation Criteria** at the end to score each applicable area.

---

## Fundamental Concern Areas

### 1. Tenant Definition and Boundaries

Every considerations document should be clear about what "tenant" means in the context of the topic.

- Is it clear what constitutes a tenant (organization, individual, team, device, workload) and how the definition affects architectural decisions?
- Does the document acknowledge that the same system may need to support different tenant granularities (e.g., B2B organizations and B2C individuals)?
- Are logical tenant boundaries distinguished from physical infrastructure boundaries?
- Does the document explain how the tenant definition drives decisions specific to this topic?

### 2. Isolation and Shared-Resource Tradeoffs

The spectrum between fully isolated and fully shared resources is the central tension of multitenancy.

- Is isolation presented as a **spectrum with tradeoffs**, not a binary choice?
- Does the document explain how the degree of isolation in this area affects cost, complexity, security, and performance?
- Are the consequences of sharing resources between tenants made explicit (data leakage risk, noisy-neighbor effects, blast radius)?
- Does the document help architects decide **where on the isolation spectrum** to position this component based on their requirements?
- Is the ability to place different tenants at different isolation levels (e.g., premium vs standard) addressed?

### 3. Scalability, Performance, and Resource Contention

Multitenant systems must handle diverse and competing tenant workloads without degradation.

- Does the document address how the topic area scales as tenant count and per-tenant usage grow?
- Is the **noisy-neighbor problem** addressed — how one tenant's usage can impact others in shared infrastructure?
- Are per-tenant resource limits, throttling, and fair-use mechanisms discussed?
- Does the document consider platform quotas, subscription limits, or service limits that constrain tenant scale?
- Are strategies for rebalancing or redistributing tenants across infrastructure covered where relevant?

### 4. Security and Trust Boundaries

Each tenant represents a trust boundary. Multitenancy amplifies the impact of security failures.

- Does the document define tenant-level trust boundaries for this topic?
- Is the **assume-breach principle** applied — verifying tenant context on every operation, not trusting identifiers alone?
- Are cross-tenant data leakage risks identified and mitigated?
- Does the document consider tenant-scoped credentials, secrets, keys, or certificates and their lifecycle?
- Are attack vectors that are unique to or amplified by multitenancy called out (e.g., subdomain takeover, tenant identifier spoofing, privilege escalation across tenants)?

### 5. Compliance, Data Sovereignty, and Governance

Tenants may operate under different regulatory regimes and data-handling requirements.

- Does the document acknowledge that tenants may have **differing compliance requirements** (industry regulations, data residency, retention policies)?
- Are data sovereignty and jurisdictional constraints considered for this topic?
- Does the document address per-tenant audit and traceability needs?
- Is the impact of compliance requirements on architectural choices (e.g., forcing dedicated resources or regional deployments) discussed?
- Are data retention, destruction, and portability obligations covered where relevant?

### 6. Cost Management and Commercial Alignment

Architecture decisions directly affect per-tenant economics and pricing viability.

- Does the document consider **per-tenant cost attribution** — can costs related to this area be measured or estimated per tenant?
- Are the cost implications of isolation-level choices made clear (dedicated vs shared resource economics)?
- Does the document address how architectural decisions in this area affect the provider's ability to offer competitive pricing models?
- Is the operational cost overhead of managing this area across many tenants acknowledged?
- Are profitability risks identified (e.g., scenarios where heavy tenant usage makes the architecture unprofitable)?

### 7. Tenant Lifecycle Impact

Tenant lifecycle events (onboarding, migration, offboarding) impose requirements on every architectural area.

- Does the document consider how **tenant onboarding** affects this topic (provisioning, configuration, initial setup)?
- Is **tenant offboarding** addressed — what happens to resources, data, or configuration in this area when a tenant leaves?
- Does the document cover **tenant mobility** — moving tenants between infrastructure, regions, or tiers?
- Are **merge and split scenarios** considered where tenants combine or divide?
- Is the transition between service tiers (e.g., trial to paid, standard to premium) covered for this topic?

### 8. Operational Excellence and Observability

Operating a multitenant system requires tenant-aware management, monitoring, and deployment.

- Does the document address how this area is **monitored and diagnosed per tenant**?
- Are **deployment and update strategies** tenant-aware (e.g., progressive rollout, per-tenant versioning, rollback)?
- Is the operational overhead of managing this area across many tenants realistic and acknowledged?
- Does the document consider **incident response** scoped to individual tenants without affecting others?
- Are automation and control-plane requirements for managing this area at scale discussed?

### 9. Reliability and Fault Isolation

Failures in multitenant systems risk cascading across tenant boundaries.

- Does the document address how **faults are contained** to prevent one tenant's failure from affecting others?
- Are **per-tenant SLA implications** discussed — can different tenants receive different reliability guarantees?
- Is disaster recovery and business continuity considered in a tenant-aware manner?
- Does the document explain how shared-component failures impact multiple tenants and what mitigations apply?
- Are capacity-planning and burst-handling strategies covered to maintain reliability under variable multi-tenant load?

### 10. Identity, Access, and Entitlements

Tenant-aware identity and access control is foundational to every multitenant component.

- Does the document address how **tenant context is established and propagated** for operations in this area?
- Are authentication and authorization models discussed in the context of multi-tenant boundaries?
- Is the separation between **identity** (who you are) and **entitlements** (what you can do per tenant) maintained?
- Does the document consider users who belong to **multiple tenants** and how this area handles tenant switching?
- Are **workload and service identities** (machine-to-machine) addressed separately from user identities where relevant?

### 11. Evolution, Extensibility, and Future-Proofing

Multitenant architectures must accommodate growth in tenant count, new capabilities, and changing requirements.

- Does the document support **incremental adoption** — can architects start simple and add multitenancy sophistication over time?
- Are migration paths between isolation levels or architectural patterns discussed?
- Does the guidance remain applicable as new Azure services, capabilities, or paradigms emerge?
- Is **backward compatibility** considered when evolving this area (e.g., API versioning, schema evolution, feature flags)?
- Does the document avoid prescribing a single solution, instead presenting a decision framework that adapts to varying requirements?

---

## Evaluation Criteria

For each fundamental concern area assessed, the reviewer should determine:

| Criterion | Question |
|-----------|----------|
| **Relevance** | Is this area applicable to the document's topic? If not, skip — but record the reasoning. |
| **Completeness** | Are the key decisions and tradeoffs for this area surfaced? |
| **Balance** | Are both technical and commercial/business perspectives present? |
| **Actionability** | Does the guidance help architects make decisions, not just list considerations? |
| **Multitenancy differentiation** | Does the guidance provide value **specific to multitenant architectures**, not just general best practices that apply equally to single-tenant systems? |
| **Spectrum thinking** | Are options presented as a range with tradeoffs, not as a single prescriptive answer? |
