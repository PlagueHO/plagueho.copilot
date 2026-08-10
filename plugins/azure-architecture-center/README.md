# Azure Architecture Center Plugin

Plugin for Azure Architecture Center documentation maintainers. Reviews
multitenant guidance and documentation for currency, accuracy, and completeness.

## Installation

```bash
# Using Copilot CLI
copilot plugin install azure-architecture-center@plagueho-copilot
```

## What's Included

### Commands (Slash Commands)

| Command | Description |
|---------|-------------|
| `/azure-architecture-center:discover-multitenant-service-updates` | Discover new or changed Azure service features that may need to be added to an AAC multitenant service-specific guidance document. Use BEFORE updating a doc. |
| `/azure-architecture-center:review-multitenant-service-specific-doc` | Review AAC multitenant service-specific documentation for accuracy, structure, and product correctness. |
| `/azure-architecture-center:review-multitenant-approaches-doc` | Review AAC multitenant approaches documentation for accuracy, structure, and product correctness. |
| `/azure-architecture-center:review-multitenant-considerations-doc` | Review AAC multitenant considerations documentation for accuracy, structure, and product correctness. |

### Agents

| Agent | Description |
|-------|-------------|

## Source

This plugin is part of [PlagueHO/plagueho.copilot](https://github.com/PlagueHO/plagueho.copilot), the Copilot resource catalog for Daniel Scott-Raynsford.

## License

MIT
