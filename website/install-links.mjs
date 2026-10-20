const githubBase = "https://github.com/PlagueHO/plagueho.copilot";
const marketplaceBranch = "marketplace";
const marketplaceSource = `PlagueHO/plagueho.copilot#${marketplaceBranch}`;
const marketplaceName = "plagueho-copilot";

function createCopilotAppLauncher(appLink) {
  return `https://github.com/copilot/app/launch?open=${encodeURIComponent(appLink)}`;
}

export function createInstallLinks(pluginName) {
  const pluginSource = `${pluginName}@${marketplaceName}`;

  return {
    directInstallUrl: `${githubBase}/tree/${marketplaceBranch}/plugins/${pluginName}`,
    pluginName,
    marketplaceSource,
    marketplaceName,
    marketplaceAddUrl: createCopilotAppLauncher(
      `ghapp://plugins/marketplace/add?source=${encodeURIComponent(marketplaceSource)}`,
    ),
    copilotAppInstallUrl: createCopilotAppLauncher(
      `ghapp://plugins/install?source=${encodeURIComponent(pluginSource)}`,
    ),
    vscodeInstallUrl: `vscode://chat-plugin/install?source=${encodeURIComponent(marketplaceSource)}&plugin=${encodeURIComponent(pluginName)}`,
    vscodeInsidersInstallUrl: `vscode-insiders://chat-plugin/install?source=${encodeURIComponent(marketplaceSource)}&plugin=${encodeURIComponent(pluginName)}`,
    marketplaceAddCommand: `copilot plugin marketplace add ${marketplaceSource}`,
    installCommand: `copilot plugin install ${pluginSource}`,
  };
}
