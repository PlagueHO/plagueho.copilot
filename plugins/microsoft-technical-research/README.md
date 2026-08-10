# Microsoft Technical Research

Deep technical research on Microsoft technologies with multi-agent
orchestration and structured documentation output.

## Skills

| Skill | Description |
|-------|-------------|
| [initiate-microsoft-researcher](../../skills/initiate-microsoft-researcher/) | **MANDATORY entry point** — validates topic, confirms plan with user, scaffolds folder structure, creates `.initiated` marker. |
| [create-microsoft-research-plan](../../skills/create-microsoft-research-plan/) | Generate structured research plans with scope, areas, search terms, and output mapping. |
| [research-note-template](../../skills/research-note-template/) | Extract structured notes from sources using standardized extraction rules. |
| [research-output-scaffolding](../../skills/research-output-scaffolding/) | Scaffold the .research/ folder structure with note directories and section placeholders. |

## Agents

| Agent | Description |
|-------|-------------|
| [research-microsoft-technology](../../agents/research-microsoft-technology.agent.md) | Orchestrator — coordinates the full research lifecycle from plan to finished output. |
| [research-source-discovery](../../agents/research-source-discovery.agent.md) | Discovers and ranks candidate sources across all enabled research areas. |
| [research-deep-reader](../../agents/research-deep-reader.agent.md) | Fetches sources and extracts structured notes following extraction rules. |
| [research-content-writer](../../agents/research-content-writer.agent.md) | Synthesizes notes into polished output sections with full attribution. |
| [research-quality-reviewer](../../agents/research-quality-reviewer.agent.md) | Reviews output for attribution, completeness, and source validity. |

## Research Workflow

```text
┌────────────────────────────────────────────────────────────────────┐
│ Phase 1 — INITIATE (mandatory entry point)                        │
│                                                                    │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────────┐      │
│  │  Plan Skill │───▶│ User Confirm │───▶│   Scaffolding    │      │
│  └─────────────┘    │  (BLOCKING)  │    └──────────────────┘      │
│                     └──────────────┘           │                  │
│                                          .initiated ✅            │
└────────────────────────────────────────────────┼───────────────────┘
                                                 │
                                                 ▼
                                          ┌─────────────┐
                                          │ Orchestrator │
                                          └──────┬──────┘
                                                 │
                  ┌──────────────────────────────┼────────────────────┐
                  ▼                              ▼                    ▼
         ┌────────────────┐          ┌────────────────┐   ┌──────────────────┐
 Phase 2 │Source Discovery│ Phase 3  │  Deep Reader   │ 4 │ Content Writer   │
         └────────────────┘          └────────────────┘   └──────────────────┘
                                                                    │
                                                                    ▼
                                                         ┌──────────────────┐
                                                  Phase 5│Quality Reviewer  │
                                                         └──────────────────┘
                                                                    │
                                                            Phase 6 ▼
                                                         ┌──────────────────┐
                                                         │ Iterate/Complete │
                                                         └──────────────────┘
```

> **Important**: The orchestrator agent is FORBIDDEN from performing research
> directly. It MUST dispatch subagents for all research phases. The
> `initiate-microsoft-researcher` skill is the only entry point and creates a
> `.initiated` marker that the orchestrator checks before dispatching any
> subagent.

### Tool Restrictions

The orchestrator agent intentionally has a **restricted tool set**
(`vscode`, `read`, `agent`, `edit`, `todo`) — it cannot access `web`,
`browser`, `search`, or `microsoft-learn/*` tools. This is enforced at the
platform level to prevent the orchestrator from bypassing subagents and
performing research directly. Each subagent has only the tools it needs
(principle of least privilege).

### Progress Reporting

The orchestrator reports a brief status update to the user **between every
phase** (e.g., "Phase 2 complete — discovered 23 sources across 5 areas.
Moving to Phase 3…"). This gives visibility during autonomous research
phases.

## Output Structure

All research output is written to `.research/<topic-slug>/` in the
workspace root:

```text
.research/<topic-slug>/
├── plan.md              # Research plan (scope, areas, search terms)
├── log.md               # Activity log (all agent actions)
├── sources.md           # Discovered sources with relevance scores
├── review.md            # Quality review report
├── notes/
│   ├── docs/            # Microsoft Learn documentation notes
│   ├── tech/            # Technical documentation notes
│   ├── blogs/           # Blog and article notes
│   ├── arch/            # Architecture pattern notes
│   ├── samples/         # Code sample notes
│   ├── solutions/       # Solution accelerator notes
│   └── other/           # Community and third-party notes
└── output/
    ├── README.md        # Section index with status
    ├── 01-overview.md   # Synthesized output sections
    ├── 02-architecture.md
    └── ...
```

## Research Purposes

| Purpose | Description | Target Audience |
|---------|-------------|-----------------|
| `deep-guide` | Comprehensive technical reference | Architects, senior engineers |
| `presentation` | Tech talk or demo deck | Conference/meetup attendees |
| `lab` | Hands-on workshop exercises | Developers learning through practice |
| `demo` | Sample solution or proof-of-concept | Developers evaluating for adoption |

## Usage

### VS Code (Agent Mode)

Select the `research-microsoft-technology` agent in the Copilot Chat panel,
then describe the research topic and purpose:

```text
@research-microsoft-technology research Azure Container Apps dynamic sessions for a deep-guide
```

Or switch to the agent mode and invoke it naturally:

```text
Research Azure AI Foundry agent evaluation for a presentation
```

The agent will invoke the `initiate-microsoft-researcher` skill, present the
plan for your approval, and then coordinate all subagents automatically.

### Copilot CLI

Use the `--agent` flag to invoke the orchestrator from the terminal:

```bash
gh copilot chat --agent research-microsoft-technology \
  "Research Azure Container Apps dynamic sessions for a deep-guide"
```

### Important Notes

- **Always invoke the `research-microsoft-technology` agent** — do not invoke
  the `initiate-microsoft-researcher` skill directly. The skill is
  non-user-invocable and is called internally by the orchestrator agent.
- The orchestrator **always** begins with the `initiate-microsoft-researcher`
  skill. You will be asked to confirm the plan before any research starts.
- If you provide source URLs in your prompt, they will be included in the
  plan's search terms automatically.
- All output is written to `.research/<topic-slug>/` in the workspace root.
- You can resume an interrupted research project by invoking the agent again
  with the same topic — it will detect the existing `.initiated` marker and
  continue from where it left off.
