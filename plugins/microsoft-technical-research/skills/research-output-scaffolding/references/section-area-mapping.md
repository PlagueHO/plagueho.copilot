# Section-to-Area Mapping

Defines which research note areas contribute to each output section and
the priority order for synthesis.

## Synthesis Rules

1. **Primary areas** are read first — they form the backbone of the section
2. **Secondary areas** supplement with additional context and examples
3. Within each area, notes are processed in chronological extraction order
4. Conflicting information between notes triggers a quality review flag

## Deep Guide Sections

| Section | Primary Areas | Secondary Areas | Min Notes Required |
|---------|---------------|-----------------|-------------------|
| 01-overview | docs, blogs | other | 3 |
| 02-architecture | arch, docs | tech | 3 |
| 03-getting-started | docs, samples | solutions | 2 |
| 04-configuration | docs, tech | samples | 3 |
| 05-security | docs, arch | tech | 2 |
| 06-operations | docs, tech | blogs | 2 |
| 07-integration | arch, samples, solutions | docs | 3 |
| 08-samples | samples, solutions | docs, other | 2 |
| 09-limitations | docs, tech | blogs, other | 2 |

## Presentation Sections

| Section | Primary Areas | Secondary Areas | Min Notes Required |
|---------|---------------|-----------------|-------------------|
| 01-hook | docs, blogs | other | 2 |
| 02-solution | docs, arch | blogs | 2 |
| 03-architecture | arch, docs | — | 2 |
| 04-demo-flow | samples | docs | 1 |
| 05-deep-dive | docs, arch | other | 2 |
| 06-comparison | other, blogs | docs | 2 |
| 07-resources | docs, samples | other | 1 |

## Lab Sections

| Section | Primary Areas | Secondary Areas | Min Notes Required |
|---------|---------------|-----------------|-------------------|
| 00-prerequisites | docs, tech | samples | 2 |
| 01-exercise | docs, samples | — | 2 |
| 02-exercise | samples, docs | tech | 2 |
| 03-exercise | samples, solutions | arch | 2 |
| 04-exercise | solutions, samples | other | 1 |
| cleanup | docs | — | 1 |

## Demo Sections

| Section | Primary Areas | Secondary Areas | Min Notes Required |
|---------|---------------|-----------------|-------------------|
| 01-overview | docs | blogs | 2 |
| 02-architecture | arch, solutions | docs | 2 |
| 03-setup | docs, samples | tech | 2 |
| 04-walkthrough | samples, solutions | docs | 2 |
| 05-extend | solutions, other | docs, tech | 1 |
