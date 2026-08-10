# Research Dimension Taxonomy

Fixed taxonomy of research dimensions for Microsoft technology research.
Each dimension represents a category of information to investigate.

## Dimensions

| ID | Dimension | Description |
|----|-----------|-------------|
| `overview` | Overview and Positioning | What it is, when to use it, value proposition, competitive positioning |
| `architecture` | Architecture and Components | Internal architecture, component relationships, data flows, deployment models |
| `configuration` | Configuration and Deployment | Setup, configuration options, parameters, deployment patterns, prerequisites |
| `security` | Security and Identity | Authentication, authorization, network security, compliance, data protection |
| `networking` | Networking and Connectivity | Network topology, endpoints, DNS, load balancing, private connectivity |
| `monitoring` | Monitoring and Observability | Metrics, logs, alerts, diagnostics, troubleshooting, health checks |
| `pricing` | Pricing and SKUs | Cost model, SKU comparison, pricing tiers, cost optimization strategies |
| `limits` | Limitations and Quotas | Service limits, quotas, known constraints, unsupported scenarios, roadmap items |
| `integration` | Integration Patterns | Related services, event-driven patterns, API connectivity, ecosystem |
| `migration` | Migration Paths | Moving from other services, upgrade paths, compatibility considerations |
| `sdks` | SDKs and APIs | Client libraries, REST APIs, CLI tools, language support, SDK patterns |
| `samples` | Code Samples | Reference implementations, quickstarts, end-to-end examples |

## Area-to-Dimension Mapping

Each research area contributes to specific dimensions:

| Area | Primary Dimensions | Secondary Dimensions |
|------|-------------------|---------------------|
| `docs` | overview, configuration, security, limits | architecture, networking, monitoring |
| `tech` | sdks, configuration, networking | security, integration |
| `blogs` | overview, migration | limits, pricing |
| `arch` | architecture, integration, security | networking, monitoring |
| `samples` | samples, sdks, configuration | integration |
| `solutions` | samples, integration, architecture | configuration, migration |
| `other` | limits, migration, integration | overview, pricing |
