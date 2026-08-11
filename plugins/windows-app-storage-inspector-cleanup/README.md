# Windows App Storage Inspector & Cleanup

Inspect Windows application storage, understand local disk usage, and safely move approved cleanup items to the Recycle Bin.

## Installation

Install the plugin in the GitHub Copilot app:

```text
copilot plugin install windows-app-storage-inspector-cleanup@plagueho-copilot
```

## Source

The reusable canvas source is in [`extensions/windows-app-storage-inspector-cleanup`](../../extensions/windows-app-storage-inspector-cleanup/).

## Platform

This canvas extension supports Windows only.

## Safety

The canvas is inspection-only by default. The **Allow Delete** switch starts disabled, so the canvas cannot move files or folders during normal direct cleanup until the user deliberately enables it and acknowledges the risk.

When direct cleanup is enabled, selected files and folders are moved to the Windows Recycle Bin rather than permanently deleted. Recycle Bin recovery is not guaranteed, so review every path and the cleanup preview carefully before confirming an operation.

The **Protect analyzer folders** switch is enabled by default. Custom analyzers are provided for managed storage where manually deleting files or folders is not recommended, such as Docker, npm, and uv data. Use the analyzer's supported commands whenever possible.

Analyzer-folder protection can be overridden by disabling the switch, but doing so can expose managed content to direct cleanup after a rescan. Take care in all situations: removing the wrong data can break applications, invalidate environments, remove downloaded models, or cause data loss. Only remove content when you understand its purpose and have an appropriate backup or recovery plan.

## License

MIT
