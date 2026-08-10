---
name: review-multitenant-service-specific-doc

description: >-
  **ANALYSIS SKILL** — Review Azure Architecture Center multitenant
  service-specific documentation for accuracy, structure, and
  correctness. Produces a review report with severity and confidence
  ratings. WHEN: "review multitenant service doc", "review service doc",
  "review AAC service doc", "multitenant service review",
  "review service-specific doc", "check service doc structure".
  INVOKES: microsoft-learn MCP, subagent, search, read.
  FOR SINGLE OPERATIONS: Use Microsoft Learn MCP directly.

metadata:
  author: PlagueHO
  version: "2.0"
  reference: https://learn.microsoft.com/en-us/azure/architecture/guide/multitenant/overview

compatibility: >-
  GitHub Copilot, VS Code. Requires microsoft-learn MCP tools
  (microsoft_docs_search, microsoft_docs_fetch,
  microsoft_code_sample_search) and subagent support.
---

# Review AAC Multitenant Service-Specific Documentation

Target documents: `service/` subfolder under `/docs/guide/multitenant/`. Review for technical accuracy, structural consistency, and product correctness.

> **Important:** "Tenant" means your customers or user groups — not Microsoft Entra tenants. Do not confuse these concepts.
>
> **Scope exclusion — Microsoft Learn Build checks:** Do NOT review for general link validity, clarity, consistency, inclusive language, terminology, or tone — the Microsoft Learn Build service validates these. HOWEVER, review clarity, consistency, and terminology **specifically for multitenancy and SaaS concepts** (domain-specific, not covered by Build).

See [review-framework.md](references/review-framework.md) for the review dimensions checklist used in Step 4.

## Prerequisites

- **Microsoft Learn MCP tools** — `microsoft_docs_search`, `microsoft_docs_fetch`, `microsoft_code_sample_search` to verify technical claims against official docs.
- **Subagent tools** — to research Azure service features, limits, preview/deprecation status.
- **Search tool** — to locate patterns and cross-references.
- **Read tool** — to read the target document and related files.

## MCP Tools Used

| Step | Tool | Query Pattern | Purpose |
|------|------|---------------|----------|
| 3 | `microsoft_docs_search` | `"<service> multitenancy best practices"` | Find multitenant guidance |
| 3 | `microsoft_docs_fetch` | URL from search results | Retrieve full doc pages |
| 3 | `microsoft_docs_search` | `"<service> limits quotas"` | Verify service limits |
| 3 | `microsoft_docs_search` | `"<service> preview features"` | Check preview/GA status |
| 3 | `microsoft_docs_search` | `"<service> deprecation retirement"` | Check deprecation status |
| 3 | `microsoft_code_sample_search` | `"<service> <feature>"` | Validate code samples |

**CLI Fallback (if MCP unavailable):** Browse `https://learn.microsoft.com/en-us/azure/<service>/` and search for multitenancy content manually.

## Process

### Step 1 — Verify Front Matter and ms.date

1. Read the target document.
2. Verify YAML front matter is valid and contains required fields.
3. Verify `ms.date` is present and in US date format (`mm/dd/yyyy`).
4. Flag significantly outdated `ms.date` — the date should reflect the most recent review.

### Step 2 — Verify Structure

Read [service-template.md](references/service-template.md). The template is a starting point, not a strict contract — focus on topic coverage, not exact section names or ordering.

1. Key topics covered (may appear under different headings or order):
   - Introduction (service in a multitenant context)
   - Features supporting multitenancy (subsections per feature)
   - Isolation models (with comparison table)
   - Service-specific considerations
   - Contributors (with LinkedIn links)
   - Related resources / Next steps
2. Heading levels follow proper hierarchy (no skipped levels).
3. Comparison table has correct columns: Consideration, one column per isolation model, Example scenario.
4. Comparison table includes applicable rows: Data isolation, Performance isolation, Deployment complexity, Operational complexity, Resource cost.
5. Benefits/Trade-offs subsections present for each isolation model.

Flag missing topics as 🟠 Important. Flag ordering or naming deviations as ℹ️ Info only.

### Step 3 — Verify Product Documentation Correctness

**Critical step.** Use MCP tools and subagent research to validate every product claim, feature description, and technical recommendation.

#### 3a — Product Information Correctness

- Azure service names are current (not deprecated or renamed).
- Feature descriptions match official product docs.
- Quotas, limits, and pricing models are accurate.
- Configuration options and parameters are correct.
- Code samples match official patterns.

#### 3b — Multitenancy Examples and Patterns

- Multitenancy feature examples reflect actual product behavior.
- Isolation patterns work as described in official docs.
- Service limits relevant to multitenancy patterns (e.g., max instances, connections, throughput) are correct and cited. Include known limit value in findings if missing.

#### 3c — Preview and Deprecation Status

- Flag preview features presented as generally available.
- Flag deprecated or retiring features recommended without noting their status (critical finding).

#### 3d — Multitenancy Relevance Validation

- Each feature claimed as a multitenancy benefit must provide **unique value in a multitenant context**, not general benefits applying equally to single-tenant deployments.
- Features must explain differentiated advantages (e.g., tenant isolation, per-tenant scaling, noisy-neighbor mitigation, cost allocation).

### Step 4 — Check Multitenancy Coverage

Evaluate coverage against Multitenancy Principles:

- **Isolation requirements** — Covers isolation options and tradeoffs.
- **Noisy neighbor** — Referenced for shared resources; links to antipattern article.
- **Cost allocation** — Mentions measurement challenges; links to consumption guidance.
- **Tenant lifecycle** — Covers onboarding, migration, offboarding, schema updates where applicable.
- **Isolation spectrum** — Presents isolation as a continuum, not binary.
- **Dual focus** — Addresses both technical and commercial decisions.

Evaluate service-specific coverage using [review-framework.md](references/review-framework.md) for review dimensions, critical questions, and common pitfalls.

Service-specific checks:

- Leads with multitenancy-specific features.
- Uses consistent isolation terminology across service docs.
- Links heavily to official Azure documentation.
- Focuses on "what" and "why", not "how" (implementation belongs elsewhere).
- Uses callouts for warnings (`> [!WARNING]`).
- Code examples minimal — only when illustrative.

### Step 5 — Check Multitenancy Terminology and Clarity

- Uses "tenant" consistently (not "customer" when referring to tenants).
- Multitenancy concepts (isolation models, shared vs. dedicated, noisy neighbor) are explained clearly and correctly.
- SaaS-specific terminology is accurate.
- Diagram alt-text follows `Diagram that shows...` pattern.
- Cross-references link to related Approaches and Considerations documents.
- Links to Well-Architected Framework and Cloud Design Patterns where appropriate.

### Step 6 — Check Scope Boundaries

- **Do Not Review:** Code implementations, deployment scripts (unless illustrative), non-multitenancy content, general Azure guidance, general link validity, general style/tone/inclusive language.
- **Always Preserve:** Contributors sections with attribution.
- **Never Invent:** Azure services or features — verify against official docs.

Flag content belonging to Approaches or Considerations category (structural issue).

### Step 7 — Produce the Review Report

Output the review using [report-template.md](assets/report-template.md). Include:

1. **Document metadata** — Path, category (Service-Specific), service, ms.date status.
2. **Summary** — Brief overall assessment.
3. **Sources searched** — All MCP queries and subagent research performed.
4. **Findings table** — Each finding with severity, confidence, status, change type, and reference documentation. See severity, confidence, and status legends in [report-template.md](assets/report-template.md).
5. **Suggested changes** — Actionable change text for each finding.

## Quality Standards

- **Accurate** — Capabilities, limits, preview/deprecation status verified against official docs.
- **Consistent** — Follows established service-specific doc patterns.
- **Complete** — Covers all relevant multitenancy aspects with correct service limits.
- **Clear** — Consistent multitenancy and SaaS terminology throughout.
- **Connected** — Cross-links to Approaches, Considerations, WAF, and Cloud Design Patterns.
- **Current** — `ms.date` reflects recent review; no deprecated/preview features without status indicators.

## Edge Cases

- **Unverifiable claims** — Note as "unverified", confidence 🔴 Low; recommend manual confirmation.
- **Conflicting official sources** — Report both, flag for human resolution, confidence 🟡 Medium.
- **Wrong category content** — Flag as structural issue, severity 🔴 Critical.
- **No multitenancy guidance for service** — Note gap; suggest checking broader Azure docs.
- **Preview feature, no GA timeline** — Flag as 🟠 Important; add preview disclaimer.
- **Undocumented service limit** — Note as ℹ️ Info, confidence 🔴 Low.
