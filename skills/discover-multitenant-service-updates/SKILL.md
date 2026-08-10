---
name: discover-multitenant-service-updates

description: >-
  **DISCOVERY SKILL** — Identify new or changed Azure service features
  that may need to be added to an AAC multitenant service-specific
  guidance document. Searches Azure Updates, What's New pages, and
  Microsoft Learn to produce a gap report of multitenant-relevant
  changes since the document's last review date. Use this BEFORE
  updating a doc; use the review-multitenant-*-doc skills AFTER.
  WHEN: "discover multitenant updates", "what needs updating in
  multitenant doc", "find new Azure features for multitenant doc",
  "audit multitenant currency", "what changed since last review",
  "multitenant gap analysis", "scan service doc for updates".
  INVOKES: microsoft-learn MCP, fetch, think tools. FOR SINGLE
  OPERATIONS: Use Microsoft Learn MCP directly.

metadata:
  author: PlagueHO
  version: "2.0"
  reference: https://learn.microsoft.com/en-us/azure/architecture/guide/multitenant/overview

compatibility:
  - GitHub Copilot
  - VS Code
  - Requires microsoft-learn MCP tools
  - Requires fetch tool for Azure Updates page

argument-hint: >-
  Provide the path to the Azure Architecture Center multitenant
  service-specific guidance document to scan for needed updates (e.g.,
  "docs/multitenant/service/app-service-content.md").

user-invocable: true
---

# Discover Updates for AAC Multitenant Service-Specific Guidance

Identify new or changed Azure service features that may need to be added
to an Azure Architecture Center multitenant service-specific guidance
document. Analyze whether the document reflects the latest Azure service
features that uniquely benefit multitenant solutions, and produce a
structured gap report identifying updates needed.

> **Important:** "Tenant" means your customers or user groups — not Microsoft
> Entra tenants. Do not confuse these concepts throughout the review.
>
> **How this skill differs from the review skills:**
> This skill identifies *what might need updating* by researching Azure
> service changes since the document's last review date. It runs **before**
> you make edits. The `review-multitenant-*-doc` skills validate a document
> **after** it has been updated — checking structure, accuracy, and
> terminology. Typical workflow: run this skill first to discover gaps,
> update the document, then run the appropriate review skill.

## Prerequisites

- **Microsoft Learn MCP tools** — `microsoft_docs_search`,
  `microsoft_docs_fetch`, and `microsoft_code_sample_search` for querying
  official documentation.
- **Fetch tool** — for retrieving Azure Updates pages.
- **Think tool** — for deep reasoning about multitenant relevance.
- **Todo tool** — for tracking review progress.

## MCP Tools Used

| Step | Tool | Command | Purpose |
|------|------|---------|----------|
| 1 | `microsoft_docs_search` | search | Find What's New and multitenant docs |
| 2 | `microsoft_docs_fetch` | fetch | Retrieve full documentation pages |
| 3 | `microsoft_code_sample_search` | search | Find service-specific code samples |
| 4 | `fetch` | fetch | Retrieve Azure Updates page |

**CLI Fallback (if MCP unavailable):**
Browse Microsoft Learn directly at
`https://learn.microsoft.com/en-us/azure/<service>/` and the Azure
Updates page at `https://azure.microsoft.com/updates/`.

## Process

### Step 0 — Initialize Report

Create a `report.md` file in the current working directory using the template
at `assets/report-template.md` (relative to this skill's root). This file
captures all findings and serves as the primary output. Populate the header
fields as information becomes available throughout the review.

### Step 1 — Extract Review Metadata

Read the target document file provided by the user.

1. Parse the YAML front matter for the `ms.date:` field (format: mm/dd/yyyy).
   This is the last review date.
2. If the `.md` file has no front matter, check for a matching `.yml` file in
   the same directory (e.g., `app-service.yml` for `app-service-content.md`).
3. Extract the Azure service name from the document title.
4. Record the review date and service name in `report.md`.

### Step 2 — Search Microsoft Learn for Updates

Use `microsoft_docs_search` to find updates for the identified Azure service:

1. Search for the service "What's New" page:
   `"<service-name> what's new"`.
2. Search for multitenant-specific guidance:
   `"<service-name> multitenant"`.
3. Search for feature updates:
   `"<service-name> new features"`.
4. Use `microsoft_docs_fetch` to retrieve full content from any promising
   results, especially "What's New" pages covering the period since the last
   review date.

### Step 3 — Search Azure Updates

Use the fetch tool to retrieve the Azure Updates page for the service:

```text
https://azure.microsoft.com/updates/?searchterms=<Name+of+Azure+Service>
```

Scan results for updates published after the last review date. Focus on
features, not bug fixes or minor improvements.

### Step 4 — Continue Searching Until Exhausted

Do not stop after the first round of searches. Continue with additional
queries to cover all angles:

- Service-specific documentation pages.
- Related services that integrate with the primary service.
- Preview or GA announcements for features since the review date.
- Pricing model changes that affect multitenant isolation strategies.

Only move to the next step when confident all relevant sources are exhausted.

### Step 5 — Evaluate Multitenant Relevance

For each discovered update or new feature, use the think tool to determine
whether it is relevant in a multitenant context.

#### Relevance Criteria — Include When

A feature is relevant to multitenancy when it provides a capability that
uniquely benefits solutions serving multiple tenant groups. Examples:

- **Resource sharing** — share resources across tenant workloads (e.g.,
  Azure SQL Elastic Pools).
- **Tenant isolation** — enforce data or compute separation per tenant.
- **Tenant identification** — identify tenants on incoming requests (e.g.,
  API Management policies).
- **Tenant-scoped metadata** — tag or organize resources per tenant (e.g.,
  Key Vault secret tags).
- **Per-tenant scaling** — scale independently for individual tenants.
- **Per-tenant routing** — route traffic based on tenant context.
- **Noisy neighbor mitigation** — throttle or isolate tenant workloads.
- **Tenant onboarding/offboarding** — automate lifecycle management.

#### Relevance Criteria — Exclude When

- The feature is a general improvement not specific to multitenancy (e.g.,
  performance improvements, new VM sizes).
- The feature is already documented in the guidance document.
- The benefit applies equally to single-tenant and multitenant architectures
  with no distinguishing multitenant advantage.

### Step 6 — Build the Discovered Updates Table

For each relevant discovered update, add a row to the report table in `report.md`:

| Column | Description |
|--------|-------------|
| Status | Icon indicating documentation state (see below) |
| Change Type | `Feature`, `Improvement`, or `Bug Fix` |
| Reason | Why it matters in a multitenant context |
| Date Added | When the feature was announced or became GA |
| Reference Doc | Link to the official documentation |

**Status Icons:**

| Icon | Meaning |
|------|---------|
| ✅ | Already documented — no change needed |
| ➡️ | Already documented — change needed |
| ❌ | Not documented — should be added |
| ❓ | Documentation status unclear |
| ⛔ | Feature not applicable after analysis |

### Step 7 — Finalize Report

Complete the `report.md` file:

1. Fill in any remaining header fields (total findings, recommendation).
2. If no relevant changes were found, set the summary to:
   `🎇 No changes needed.`
3. If updates were found, add a closing section offering to provide
   suggested text for any changes that should be made to the document.
4. Write the final `report.md` to disk.

> **Important:** Do NOT modify the reviewed document itself. The report is
> the only output.

## Multitenant Feature Examples

These examples illustrate features with genuine multitenant relevance, to
calibrate the relevance threshold:

| Service | Feature | Why It Is Multitenant-Relevant |
|---------|---------|-------------------------------|
| Azure SQL Database | Elastic Pools | Share resources across per-tenant databases |
| Azure Key Vault | Secret tags | Track tenant ID per secret for management |
| Azure API Management | Request policies | Identify tenants on incoming API requests |
| Azure App Service | Deployment slots | Isolate tenant deployments for staged rollout |
| Azure Cosmos DB | Partition keys | Use tenant ID as partition key for data isolation |

## Edge Cases

- **No front matter in .md file**: Check the matching `.yml` file in the
  same directory for the `ms.date:` field.
- **No ms.date field found**: Report this in the output and use the current
  date minus 12 months as a reasonable lookback window.
- **Service name ambiguous**: Use the document title and any `ms.service`
  front matter field to resolve. If still unclear, ask the user.
- **Azure Updates page returns no results**: Try alternate service name
  spellings or abbreviations. Document the search terms attempted.

## Validation

Verify the report is complete:

1. `report.md` exists and follows the template structure.
2. All header fields are populated.
3. Every finding has all five table columns filled.
4. Status icons are correctly applied based on existing document content.
5. No modifications were made to the source document.
