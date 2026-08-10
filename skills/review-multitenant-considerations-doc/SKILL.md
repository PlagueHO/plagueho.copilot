---
name: review-multitenant-considerations-doc

description: >-
  **ANALYSIS SKILL** — Review Azure Architecture Center multitenant considerations docs for completeness, accuracy, and decision-framework quality. Considerations docs help CTOs and lead architects of SaaS/ISV companies decide if and how to adopt multitenancy. Produces a review report with severity and confidence ratings. WHEN: "review multitenant considerations doc", "review considerations doc", "review AAC considerations doc", "multitenant considerations review", "check considerations doc structure". INVOKES: microsoft-learn MCP, subagent, search, read. FOR SINGLE OPERATIONS: Use Microsoft Learn MCP directly.

metadata:
  author: PlagueHO
  version: "3.0"
  reference: https://learn.microsoft.com/en-us/azure/architecture/guide/multitenant/considerations/overview

compatibility: >-
  GitHub Copilot, VS Code. Requires microsoft-learn MCP tools (microsoft_docs_search, microsoft_docs_fetch, microsoft_code_sample_search) and subagent support.
---

# Review AAC Multitenant Considerations Documentation

Review documents in the `considerations/` subfolder of `/docs/guide/multitenant/` for decision-framework quality, multitenancy completeness, and technical accuracy. Audience: CTOs, architects, and product managers of SaaS/ISV companies planning multitenant Azure solutions.

> **"Tenant"** means your customers or user groups — not Microsoft Entra tenants.
>
> **Scope exclusion:** Do NOT review general link validity, inclusive language, or generic tone/style (Microsoft Learn Build covers these). DO review clarity and terminology **specific to multitenancy and SaaS concepts**.

## What Makes a Considerations Document

Considerations documents present **decision frameworks and strategic thinking** for CTOs and lead architects before committing to an architecture. They sit above Approaches (patterns per service category) and Service-Specific (individual Azure service detail) articles.

Considerations documents must:

- Focus on **what to think about**, not how to implement.
- Present decisions as a **spectrum of options** with tradeoffs, not prescriptive answers.
- Balance **technical and commercial** perspectives.
- Use comparison tables where options exist.
- Include Benefits/Risks for each option.
- Use "consider" language — never dictate.
- Avoid code, configuration, or service-specific implementation detail.
- Use conceptual diagrams (not implementation diagrams).
- Use interrogative subheadings (questions that guide decisions).

See [review-framework.md](references/review-framework.md) for the fundamental concern areas used in Step 4.

## Prerequisites

- **Microsoft Learn MCP tools** — `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`.
- **Subagent tools** — research Azure service features, cross-reference sources.
- **Search and Read tools** — read target document and related files.

## Process

### Step 1 — Verify Front Matter and ms.date

1. Read the target document.
2. Verify YAML front matter is valid and contains required fields.
3. Verify `ms.date` is present and in US date format (`mm/dd/yyyy`).
4. If `ms.date` is significantly outdated, flag it.

### Step 2 — Verify Structure

Read [considerations-template.md](references/considerations-template.md). Compare heading hierarchy and section order:

1. Required sections present: Introduction, Core decision-framework content (with comparison tables and Benefits/Risks per option), Contributors (with LinkedIn links), Next steps.
2. Sections in correct order; heading levels follow proper hierarchy.
3. Each option or model has both Benefits and Risks subsections.
4. No code or configuration details present.

### Step 3 — Verify Decision Framework Accuracy

Use MCP tools and subagent research to validate decision frameworks, options, and recommendations against current official docs.

| Tool | Query Pattern | Purpose |
|------|---------------|---------|
| `microsoft_docs_search` | `"<topic> multitenancy best practices"` | Validate multitenant guidance |
| `microsoft_docs_fetch` | URL from search results | Retrieve full doc pages |
| `microsoft_docs_search` | `"<topic> preview features"` | Check preview/GA status |
| `microsoft_docs_search` | `"<topic> deprecation retirement"` | Check deprecation status |

Verify:

#### 3a — Options and Frameworks Are Current

- Options reflect current Azure guidance and capabilities.
- Comparison tables contain correct, balanced information.
- Benefits and risks for each option are accurate.
- Recommendations use "consider" language (not prescriptive).

#### 3b — Preview and Deprecation Status

- Preview features are marked as such. Presenting a preview feature as GA is critical.
- Deprecated or retiring features are flagged. Recommending a deprecated feature without disclaimer is critical.

#### 3c — Multitenancy Differentiation

- Each option provides **unique value in a multitenant context** — not benefits that apply equally to single-tenant deployments.
- Options explain differentiated advantages: tenant isolation, per-tenant scaling, noisy-neighbor mitigation, cost allocation, tenant lifecycle management.
- Flag options without differentiated multitenant value.

### Step 4 — Review Multitenancy Considerations Coverage

**Most critical step.** Evaluate whether the document thoroughly covers the multitenancy considerations relevant to its topic. Use [review-framework.md](references/review-framework.md) for the fundamental concern areas — the non-functional requirements of a multitenant system that apply across any architectural topic.

For each fundamental concern area in the framework, assess:

1. **Relevance** — Does this topic have multitenancy implications in this area?
2. **Completeness** — If relevant, are the key decisions and tradeoffs surfaced?
3. **Balance** — Are both technical and commercial/business perspectives present?
4. **Actionability** — Does the guidance help architects make decisions, not just list considerations?
5. **Multitenancy differentiation** — Does the guidance provide value specific to multitenant architectures, not just general best practices?

The fundamental concern areas include (see framework for full detail and evaluation questions):

- Tenant definition and boundaries
- Isolation and shared-resource tradeoffs
- Scalability, performance, and resource contention
- Security and trust boundaries
- Compliance, data sovereignty, and governance
- Cost management and commercial alignment
- Tenant lifecycle impact
- Operational excellence and observability
- Reliability and fault isolation
- Identity, access, and entitlements
- Evolution, extensibility, and future-proofing

Not every area applies to every document. Skip areas that are genuinely not applicable, but record the reasoning in the review report. Flag areas that **should** be covered but are missing as gaps.

### Step 5 — Check Terminology and Cross-References

- Uses "tenant" consistently (not "customer" when meaning tenant).
- Multitenancy concepts (isolation models, shared vs dedicated, noisy neighbor, control plane, deployment stamp) are explained correctly.
- SaaS and ISV terminology is accurate.
- Diagram alt-text follows `Diagram that shows...` pattern.
- Cross-references link to related Considerations, Approaches, and Service-Specific documents.
- Links to Well-Architected Framework and Cloud Design Patterns where relevant.

### Step 6 — Check Scope Boundaries

Verify the document stays within considerations scope:

- **Must contain:** Decision frameworks, options with tradeoffs, strategic guidance for architects and CTOs.
- **Must not contain:** Code, configuration, deployment scripts, service-specific implementation detail, or content belonging in Approaches or Service-Specific articles.
- **Always preserve:** Contributors sections with attribution.
- **Never invent:** Azure services or features — verify against official docs.

Flag content belonging to Approaches or Service-Specific categories as a structural issue (severity 🔴 Critical).

### Step 7 — Produce the Review Report

Output the review using [report-template.md](assets/report-template.md). The template contains all required sections, severity/confidence/status legends, and change type definitions. Follow it as-is.

## Quality Standards

- **Accurate** — Decision frameworks reflect current Azure capabilities.
- **Complete** — Covers relevant multitenancy considerations thoroughly.
- **Balanced** — Technical and commercial perspectives present.
- **Clear** — Consistent multitenancy/SaaS terminology; concise.
- **Connected** — Cross-links to Approaches, Service-Specific docs, WAF, and Cloud Design Patterns.
- **Current** — `ms.date` reflects recent review; no deprecated or preview features without status indicators.

## Edge Cases

- **Unverifiable claims** — Note as "unverified" with confidence 🔴 Low; recommend manual confirmation.
- **Conflicting official sources** — Report both; flag for human resolution; confidence 🟡 Medium.
- **Wrong-category content** — Flag as structural issue, severity 🔴 Critical.
- **No multitenancy-specific guidance exists for the topic** — Note the gap; suggest checking broader Azure documentation.
- **Preview feature with no GA timeline** — Flag as 🟠 Important; add preview disclaimer.
