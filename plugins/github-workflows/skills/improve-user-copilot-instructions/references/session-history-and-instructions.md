# Session History and Instruction Discovery

Use current host capabilities as the authority for available tools. These references explain known CLI behavior. They do not guarantee support in VS Code, the Copilot app, or another CLI version.

## Session History

[Using GitHub Copilot CLI session data](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/chronicle) documents these features:

| Feature | Use in this skill |
|---------|-------------------|
| Read-only session-history queries | Prefer bounded metadata queries, followed by selected turns and outcomes. Inspect the exposed tool schema first. |
| `/chronicle search` | Can help locate correction topics if available. Its search can cover all history. Filter returned evidence to the review interval and sample. Do not assume a date-filter syntax. |
| `/chronicle tips` and `/chronicle cost-tips` | Can provide leads. Verify leads against selected source turns. Generated advice alone is not session evidence. |
| `/chronicle improve` | Do not invoke. Its scope is the current repository or working directory. It can update repository instructions after selection. |
| `/chronicle reindex` | Do not invoke as a review fallback. It rebuilds the session store and can sync session data. |

CLI slash commands are interactive features. Do not turn them into shell commands or launch a second agent to run them. A command listed in help is not necessarily available as an agent-callable tool.

If the host exposes a compatible skill or read-only history tool, inspect its scope and behavior before use. Keep the selected interval and sample limit even when a helper defaults to all history.

If history tools are absent, ask for selected exports or excerpts. Use only the supplied evidence. If timestamps or session identity are missing, ask for them or state that the weekly scope cannot be verified. Never infer unseen sessions, fabricate quotes, or scan the entire session directory.

## Personal Instruction Sources

[Adding custom instructions for GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions) documents user-level `copilot-instructions.md` and modular `instructions/**/*.instructions.md` files in the Copilot configuration directory.

- Resolve that directory from `COPILOT_HOME` when set. Otherwise use the host's documented default relative to the user's home directory. Use the operating system's path format.
- Inspect relevant modular rules and their conditions. Do not flatten conditional rules into unconditional guidance.
- Check configured `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` sources when relevant. Do not assume every instruction found there is personal or writable.
- Treat repository `AGENTS.md`, `.github/copilot-instructions.md`, and repository modular rules as context, not personal edit targets.
- Avoid assumptions about instruction precedence. The CLI documentation says that applicable sources are combined and warns against conflicts.

[The CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference) documents read-only `copilot instruction list --json`. It can help discover sources when the installed version supports it.

The listing does not prove that every active source is present. Managed settings and trusted repository settings can change which instructions apply. Use session discovery such as `/instructions` only when available through the host. Ask for missing personal sources rather than claiming a complete inventory.

Other hosts can store personal instructions in settings rather than files. Use their supported read-only inspection path, or ask the user to supply the current text and approved target. Do not create a CLI file to replace a source from another host.

Machine-level guidance can be managed policy. Read it only through permitted access. Propose a handoff when edits require an administrator or another owner. Do not change permissions or weaken policy.

## Applying Changes

Re-read the selected target immediately before an approved edit. A changed baseline requires a revised proposal and new approval. An approval for one source does not authorize an edit to another.

The CLI instruction guide says that file changes do not update instructions already loaded in an active session. Verify the current host's reload behavior before giving restart or resume steps. Do not restart or switch the user's session automatically.
