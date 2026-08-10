# Multitenant Documentation Review Report

| Field | Value |
|-------|-------|
| **Document Reviewed** | <!-- path to the reviewed document --> |
| **Category** | <!-- Approaches / Considerations / Service-Specific --> |
| **Azure Service** | <!-- name of the Azure service (if applicable) --> |
| **ms.date Value** | <!-- ms.date from front matter (mm/dd/yyyy) --> |
| **ms.date Status** | <!-- ✅ Current / ⚠️ Outdated (expected: today's date) --> |
| **Review Performed** | <!-- today's date (yyyy-mm-dd) --> |
| **Total Findings** | <!-- number of rows in findings table --> |
| **Recommendation** | <!-- 🎇 No changes needed / ⚠️ Updates recommended --> |

## Summary

<!-- Brief summary. If no changes needed:
🎇 No changes needed. The document is current and reflects the latest
multitenant-relevant features for this service. -->

## Sources Searched

| Source | Search Terms / URL | Results Found |
|--------|--------------------|---------------|
| Microsoft Learn (docs search) | <!-- search query --> | <!-- count --> |
| Microsoft Learn (docs fetch) | <!-- URLs fetched --> | <!-- count --> |
| Microsoft Learn (limits/quotas) | <!-- search query --> | <!-- count --> |
| Microsoft Learn (preview features) | <!-- search query --> | <!-- count --> |
| Microsoft Learn (deprecation) | <!-- search query --> | <!-- count --> |
| Subagent Research | <!-- research topic --> | <!-- summary --> |
| <!-- additional sources --> | <!-- terms --> | <!-- count --> |

## Findings

| # | Severity | Confidence | Status | Change Type | Section | Description | Reference Doc |
|---|----------|------------|--------|-------------|---------|-------------|---------------|
| <!-- 1 --> | <!-- 🔴🟠🟡ℹ️ --> | <!-- 🟢🟡🔴 --> | <!-- ✅➡️❌❓⛔ --> | <!-- type --> | <!-- heading or line --> | <!-- what and why --> | <!-- [Title](URL) --> |

### Severity Legend

| Icon | Level | Definition |
|------|-------|------------|
| 🔴 | Critical | Incorrect product info, wrong service limits, deprecated feature without disclaimer, preview feature shown as GA, verified technical inaccuracy |
| 🟠 | Important | Missing key topic coverage, incomplete multitenancy coverage, feature lacks unique multitenant differentiation, missing relevant service limit references, significantly outdated ms.date |
| 🟡 | Minor | Multitenancy terminology inconsistency, diagram alt-text pattern deviation |
| ℹ️ | Info | Suggestion for improvement — not an issue (e.g., additional features worth mentioning, cross-references to related AAC/WAF/pattern docs, section ordering deviations from template) |

### Confidence Legend

| Icon | Level | Definition |
|------|-------|------------|
| 🟢 | High | Verified against official Microsoft documentation via MCP tools or subagent research |
| 🟡 | Medium | Based on general knowledge but not fully verified against a specific official source |
| 🔴 | Low | Suspicion or inference — requires manual verification |

### Status Legend

| Icon | Meaning |
|------|---------|
| ✅ | Already documented — no change needed |
| ➡️ | Already documented — change needed |
| ❌ | Not documented — should be added |
| ❓ | Documentation status unclear |
| ⛔ | Feature not applicable after analysis |

### Change Type Values

| Type | When to use |
|------|-------------|
| Product Correctness | Feature description, limit, or behavior is inaccurate |
| Preview Status | Feature preview/GA status is missing or incorrect |
| Deprecation | Feature is deprecated or retiring without disclaimer |
| Multitenancy Relevance | Feature does not provide unique multitenant benefit |
| Service Limit | Relevant service limit not referenced, or hardcoded limit value that should link to official docs instead |
| Structure | Missing key topic from template (Important) or section ordering/naming deviation (Info) |
| Multitenancy Coverage | Missing multitenancy-specific concern |
| Terminology | Multitenancy/SaaS terminology issue |
| Cross-Reference | Missing link to related AAC/WAF/pattern doc (Info severity — informational, not blocking) |
| ms.date | Front matter date is outdated |

## Suggested Changes

<!-- For each finding marked ➡️ or ❌, provide actionable change text.
Group by finding number. Remove this section if no changes needed.

### Finding #[n]

**Current text:**
> [existing text from the document]

**Suggested text:**
> [replacement text with correction]

**Rationale:** [why this change is needed, with reference link]

-->
