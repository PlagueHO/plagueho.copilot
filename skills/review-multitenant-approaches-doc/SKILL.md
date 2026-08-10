---
name: review-multitenant-approaches-doc

description: >-
  **ANALYSIS SKILL** — Review AAC multitenant approaches docs for accuracy, structure, and product correctness. Produces a review report with severity and confidence ratings.
  WHEN: "review multitenant approaches doc", "review approaches doc", "review AAC approaches doc", "multitenant approaches review", "check approaches doc structure".
  INVOKES: microsoft-learn MCP, subagent, search, read.
  FOR SINGLE OPERATIONS: Use Microsoft Learn MCP directly.

metadata:
  author: PlagueHO
  version: "3.1"
  reference: https://learn.microsoft.com/en-us/azure/architecture/guide/multitenant/approaches/overview

compatibility: >-
  GitHub Copilot, VS Code. Requires microsoft-learn MCP tools (microsoft_docs_search, microsoft_docs_fetch, microsoft_code_sample_search) and subagent support.
---

# Review AAC Multitenant Approaches Documentation

Review documents in the `approaches/` subfolder of `/docs/guide/multitenant/` for technical accuracy, structural consistency, and multitenancy correctness.

> **"Tenant"** means your customers or user groups — not Microsoft Entra tenants.
>
> **Scope exclusion:** Do NOT review general link validity, inclusive language, or generic tone/style (Microsoft Learn Build covers these). DO review clarity and terminology **specific to multitenancy and SaaS concepts**.

## What Makes an Approaches Document

Approaches documents describe **architectural patterns and strategies** for a service category (compute, networking, storage, identity, etc.) in a multitenant context. They sit between Considerations articles (cross-cutting concerns) and Service-Specific articles (individual Azure service detail).

Approaches documents must:

- Focus on **patterns and strategies** — Azure services are illustrative only.
- Present the **isolation spectrum** (fully shared → fully dedicated) with tradeoffs at each point.
- Address **what is unique about multitenancy** for the category — not repeat general Azure guidance.
- Reference **Deployment Stamps** where applicable as a scaling strategy.
- Reference the **noisy neighbor problem** for shared resources, linking to the antipattern article.
- Keep recommendations concise and actionable.

See [review-framework.md](references/review-framework.md) for architectural dimensions and evaluation criteria used in Step 4.

## Prerequisites

- **Microsoft Learn MCP tools** — `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search`.
- **Subagent tools** — Azure feature, limit, and deprecation research.
- **Search and read tools** — target document and related files.

## Process

### Step 1 — Read and Classify

1. Read the target document fully.
2. Confirm it belongs in `approaches/` — not `considerations/` or `service/`.
3. Verify YAML front matter is valid and `ms.date` is in US format (`mm/dd/yyyy`). Flag significantly outdated dates.

### Step 2 — Verify Structure

Read [approaches-template.md](references/approaches-template.md). Compare against the expected section order:

1. **Introduction** — Why multitenancy matters for this category.
2. **Key considerations and requirements** — Domain-appropriate subsections (vary by topic; see template).
3. **Approaches and patterns to consider** — Named patterns with tradeoff discussion. Formal Benefits/Risks subsections are optional — inline tradeoff discussion is acceptable.
4. **Antipatterns to avoid** — Common mistakes with explanations.
5. **Contributors** — Attribution with LinkedIn links.
6. **Next steps / Related resources** — Links to related content.

Verify heading levels follow proper hierarchy (no skipped levels).

### Step 3 — Verify Technical and Product Correctness

Use MCP tools and subagent research to validate product claims and technical recommendations.

**Verify:**

- **Product info** — Service names current, features match official docs, quotas/limits accurate.
- **Patterns** — Current and reflect official Azure guidance. Antipatterns are valid.
- **Preview/deprecation** — Preview features marked as preview. Deprecated features flagged. Recommending a deprecated feature without disclaimer is 🔴 Critical.
- **Service limits** — When relevant to a pattern, the cited value must be correct. Include the known value if missing.

### Step 4 — Evaluate Multitenancy Focus

Every pattern must provide **unique value in a multitenant context** — not just general Azure best practices.

#### 4a — Cross-Cutting Multitenancy Themes

Verify coverage where relevant to the topic:

| Theme | Check |
|-------|-------|
| **Isolation spectrum** | Continuum (shared → semi-isolated → dedicated), not binary |
| **Noisy neighbor** | Explicit for shared resources; links to [antipattern](https://learn.microsoft.com/azure/architecture/antipatterns/noisy-neighbor/noisy-neighbor) |
| **Tenant lifecycle** | Onboarding, scaling, migration, offboarding |
| **Cost allocation** | Measurement challenges for shared resources; links to consumption guidance |
| **Bin packing / scale-out** | Scale across resources, resource groups, subscriptions |
| **Deployment Stamps** | Referenced as scaling or isolation strategy |
| **Dual focus** | Technical and commercial/operational implications |

Evaluate applicability based on service category — not every theme applies to every document.

Then evaluate category-specific coverage using the **architectural dimensions** in [review-framework.md](references/review-framework.md). For each relevant dimension, ask the review questions and check for red flags. Use the applicability guide (Section C) to identify which dimensions are most relevant to the document's technology category.

#### 4b — Approaches vs. General Guidance Boundary

- Each pattern must explain what is **different in a multitenant context** versus single-tenant.
- Flag patterns lacking differentiated multitenant value (e.g., "use autoscaling" without explaining tenant workload complexity).
- Azure services must be **illustrative** — if the doc reads like service-specific configuration guidance, flag as a scope issue.

#### 4c — Content That Belongs Elsewhere

Flag content belonging in:

- **Considerations** (e.g., pricing model design, tenancy model selection).
- **Service-Specific** (e.g., detailed elastic pool config, step-by-step AKS node pool setup).

### Step 5 — Check Terminology and Cross-References

- "Tenant" used consistently (not "customer" for tenants).
- Multitenancy concepts explained correctly.
- Diagram alt-text follows `Diagram that shows...` pattern.
- Cross-references to Considerations and Service-Specific docs.
- Links to Well-Architected Framework and Cloud Design Patterns.

### Step 6 — Produce the Review Report

Output using [report-template.md](assets/report-template.md):

1. **Document metadata** — Path, category, service category, ms.date status.
2. **Summary** — 2–3 sentence assessment.
3. **Sources searched** — MCP queries and subagent research.
4. **Findings table** — Severity, confidence, status, change type, section, description, reference doc.
5. **Suggested changes** — Actionable text for findings marked ➡️ or ❌.

### Severity Definitions

| Icon | Level | Definition |
|------|-------|------------|
| 🔴 | Critical | Wrong product info, wrong limits, deprecated without disclaimer, preview shown as GA, wrong category |
| 🟠 | Important | Missing sections, incomplete multitenancy coverage, no multitenant differentiation, outdated ms.date, reads like service-specific guidance |
| 🟡 | Minor | Terminology inconsistency, missing cross-references, alt-text deviation |
| ℹ️ | Info | Improvement suggestions (additional patterns or themes) |

### Confidence Definitions

| Icon | Level | Definition |
|------|-------|------------|
| 🟢 | High | Verified against official Microsoft docs via MCP or subagent |
| 🟡 | Medium | Based on general knowledge, not verified against specific source |
| 🔴 | Low | Suspicion or inference — requires manual verification |

## Scope Boundaries

- **Do Not Review:** Code, deployment scripts (unless illustrative), non-multitenancy content, general Azure guidance, general link validity, general style/tone.
- **Always Preserve:** Contributors sections.
- **Never Invent:** Azure services or features — verify against official docs.

## Edge Cases

| Scenario | Action |
|----------|--------|
| Unverifiable claims | Note "unverified", confidence 🔴 Low, recommend manual check |
| Conflicting official sources | Report both, flag for human resolution, confidence 🟡 Medium |
| Wrong category content | 🔴 Critical structural issue |
| No multitenancy guidance available | Note the gap, suggest broader Azure docs |
| Preview with no GA timeline | 🟠 Important, add preview disclaimer |
| Undocumented service limit | ℹ️ Info, confidence 🔴 Low |
