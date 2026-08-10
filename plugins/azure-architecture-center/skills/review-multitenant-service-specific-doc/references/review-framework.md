# Multitenancy Service-Specific Review Framework

Checklist for Step 4 of the review process: evaluating Azure service-specific multitenancy documents.

Do **not** treat this as a feature catalog. Service features change frequently and the documents under review are the feature reference. Use this framework to know **what dimensions to evaluate** and **how to verify claims** using Microsoft Learn MCP tools.

## Review Dimensions

Evaluate every service document against these dimensions. Each includes a review question, verification criteria, and an example issue.

### 1 — Isolation Spectrum

**Review question:** Does the document present isolation as a continuum from shared to dedicated, with tradeoffs at each level?

**What to verify:**

- At least two isolation levels are presented (e.g., shared resource with logical separation -> dedicated resource per tenant).
- Each level describes cost, complexity, and isolation strength tradeoffs.
- The document does not present isolation as binary (shared or dedicated only).

**How to verify:** Use `microsoft_docs_search` with `"<service> multitenancy"` and `"<service> isolation"` to confirm the service supports the isolation levels described. Fetch the official docs page and compare.

**Example issue:** A document presents only two extremes (fully shared or fully dedicated) without describing intermediate options the service supports (e.g., logical partitioning within a shared resource). Flag as Important — incomplete isolation coverage.

### 2 — Service Limits Relevant to Tenant Density

**Review question:** Does the document identify service limits that constrain how many tenants can share a resource?

**What to verify:**

- Limits that act as a ceiling on tenant count are mentioned (e.g., max instances, partitions, namespaces, databases, or connections per resource).
- The document explains what happens when the limit is approached and how to scale beyond it.
- The document does **not** embed specific limit values inline. Limit values change frequently. The document should reference or link to the official limits/quotas page. If a document includes a hardcoded limit value, flag it for removal and replacement with a link.

**How to verify:** Use `microsoft_docs_search` with `"<service> limits quotas"` or `"<service> subscription limits"`. Confirm the document references limits that exist and links to the official limits page rather than stating values inline.

**Example issue:** A document describes a per-tenant isolation pattern that allocates one sub-resource per tenant but does not mention that a maximum sub-resource count exists or link to the limits page. Flag as Important — missing service limit reference.

**Counter-example (not an issue):** A document states "there is a maximum number of accounts per subscription (see current limits)" and links to the official limits page. This is correct — do not flag it, and do not recommend adding the actual numeric value.

### 3 — Noisy Neighbor Mitigation

**Review question:** Does the document explain how shared resources prevent one tenant from degrading another tenant's performance?

**What to verify:**

- For each shared-resource pattern, a noisy-neighbor mitigation is described (e.g., resource quotas, rate limiting, per-tenant scaling, throttling).
- The antipattern is referenced where applicable.
- Monitoring or alerting for per-tenant resource consumption is mentioned.

**How to verify:** Use `microsoft_docs_search` with `"<service> throttling"` or `"<service> resource quotas"` to confirm the mitigation mechanisms exist.

**Example issue:** A document recommends sharing a resource among tenants but does not mention any mechanism to prevent one tenant from consuming all capacity. Flag as Important — missing noisy-neighbor mitigation.

### 4 — Data Isolation and Encryption

**Review question:** Does the document cover data separation and per-tenant encryption options?

**What to verify:**

- Data isolation patterns are described (e.g., separate stores, logical partitioning, row-level filtering).
- Encryption options note whether customer-managed keys (CMK) can be scoped per tenant or only per resource/account.
- Risks of misconfiguration in data isolation (e.g., missing filter predicates) are called out.

**How to verify:** Use `microsoft_docs_search` with `"<service> encryption customer-managed keys"` and `"<service> data isolation"`.

**Example issue:** A document claims per-tenant encryption but the service only supports CMK at the account level, requiring a separate account per tenant for true cryptographic isolation. Flag as Critical if the doc implies per-tenant CMK exists at a lower scope.

### 5 — Network Isolation

**Review question:** Does the document address network-level tenant isolation where applicable?

**What to verify:**

- Private endpoints, VNet integration, or other network isolation mechanisms are described for the service.
- The document explains when shared-resource patterns require additional network configuration (e.g., DNS, subnet sizing).
- The document notes IP address or subnet consumption implications for per-tenant network isolation.

**How to verify:** Use `microsoft_docs_search` with `"<service> private endpoint"` or `"<service> VNet integration"`.

**Example issue:** A document describes VNet integration but does not mention that each instance consumes a subnet IP address, which limits tenant density per subnet. Flag as Minor — missing network capacity detail.

### 6 — Tenant Lifecycle

**Review question:** Does the document address onboarding, migration, and offboarding of tenants?

**What to verify:**

- Onboarding: How to provision per-tenant resources or configuration.
- Migration: How to move a tenant between isolation levels (e.g., from shared to dedicated).
- Offboarding: How to clean up tenant resources and data.
- Schema or configuration updates across tenants.

**Example issue:** A document covers provisioning but does not address what happens when a tenant leaves — no data cleanup or resource decommissioning guidance. Flag as Important — incomplete tenant lifecycle coverage.

### 7 — Cost Allocation

**Review question:** Does the document address measuring and attributing costs per tenant?

**What to verify:**

- For shared resources, the document mentions the challenge of per-tenant cost measurement.
- Tagging, metering, or per-tenant billing patterns are referenced where applicable.
- Links to the consumption and cost allocation guidance.

**Example issue:** A document recommends a shared resource for cost savings but does not explain how to attribute costs to individual tenants. Flag as Minor — missing cost allocation discussion.

### 8 — Preview and Deprecation Status

**Review question:** Are all features presented with accurate availability status?

**What to verify:**

- Features in **preview** are marked as such. A feature presented as generally available must actually be GA.
- Features on a **deprecation path** include a disclaimer. A recommended feature that is deprecated without a note is a critical finding.

**How to verify:** Use `microsoft_docs_search` with `"<service> preview features"` and `"<service> deprecation retirement"`. Cross-reference the service's official "What's new" or retirement announcements.

**Example issue:** A document recommends a feature as a primary pattern, but the feature has been announced for retirement with a migration deadline. Flag as Critical — deprecated feature recommended without disclaimer.

### 9 — Multitenancy Relevance

**Review question:** Does each feature described provide unique value in a multitenant context?

**What to verify:**

- Each feature claimed as a multitenancy benefit explains its differentiated value versus single-tenant usage (e.g., tenant isolation, per-tenant scaling, noisy-neighbor mitigation, cost allocation).
- General service features that apply equally to single-tenant deployments are not presented as multitenancy-specific benefits.

**Example issue:** A document lists a general high-availability feature as a multitenancy benefit, but it provides identical value in a single-tenant deployment. Flag as Important — feature lacks unique multitenant differentiation.

### 10 — Cross-References and Context

**Review question:** Does the document link to related AAC documents, Well-Architected Framework guidance, and Cloud Design Patterns?

> **Severity guidance:** Cross-reference findings are informational (ℹ️ Info), not blocking. The goal is not a laundry list of links. Flag missing cross-references as suggestions, not required changes.

**What to verify:**

- Links to the most relevant Approaches and Considerations documents in the multitenancy guide.
- Links to the Well-Architected Framework where directly applicable.
- Links to Cloud Design Patterns when the document discusses a pattern by name (e.g., Sharding, Deployment Stamps, Throttling).
- Links to the service's official Azure documentation.

**Example issue:** A document discusses throttling-based isolation but does not link to the Throttling pattern in Cloud Design Patterns. Flag as ℹ️ Info — consider adding cross-reference.

## Generic Critical Questions

Apply these to every service document regardless of service category:

1. Does the document present isolation as a spectrum with at least two levels and their tradeoffs?
2. Are service limits that constrain tenant density referenced (not hardcoded) and linked to official documentation?
3. Is noisy-neighbor mitigation described for every shared-resource pattern?
4. Are data isolation and per-tenant encryption options covered with accurate scope (per-account vs per-resource)?
5. Is tenant lifecycle (onboarding, migration, offboarding) addressed?
6. Is cost allocation for shared resources discussed?
7. Are all features current — no deprecated features without disclaimer, no preview features presented as GA?
8. Does every feature listed provide unique multitenant value beyond single-tenant usage?
9. Does the document cover the key topics from the template (topic coverage matters more than exact section names or ordering)?
10. Does the document focus on "what" and "why" rather than "how"?

## Generic Common Pitfalls

Flag any occurrence of these pitfalls across service categories:

- **Missing isolation spectrum** — only shared or only dedicated pattern presented, omitting intermediate options the service supports.
- **Undocumented ceiling** — per-tenant pattern relies on a sub-resource that has a hard limit, but the limit is not referenced or linked to.
- **Hardcoded limit value** — document embeds a specific numeric limit instead of linking to the official limits page. Limit values change and become stale.
- **No noisy-neighbor mitigation** — shared pattern described without any mechanism to prevent one tenant from consuming all capacity.
- **Data isolation misconfiguration risk** — shared-data pattern without noting the risk of missing filter predicates or misconfigured access policies.
- **Stale feature status** — preview feature presented as GA, or deprecated feature recommended without noting its retirement path.
- **General feature as multitenant benefit** — feature provides no differentiated value in a multitenant context versus single-tenant.
- **Missing tenant lifecycle** — no guidance on how tenants are provisioned, migrated, or offboarded.
- **Scope creep** — document includes implementation how-to content that belongs in separate implementation guides, or contains content belonging to the Approaches or Considerations category.
