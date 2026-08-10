export interface CategoryConfig {
  cat: string;
  color: string;
  icon: string;
}

export const CATEGORIES: Record<string, CategoryConfig> = {
  'azure-architecture-center':       { cat: 'docs',       color: '#F4A876', icon: 'book' },
  'azure-infrastructure-deployment': { cat: 'automation', color: '#C898FD', icon: 'cloud' },
  'content-and-learning':            { cat: 'learn',      color: '#F08A3A', icon: 'graduate' },
  'developer-environment':           { cat: 'dev',        color: '#60a5fa', icon: 'terminal' },
  'dotnet-modernization':            { cat: 'dev',        color: '#60a5fa', icon: 'dotnet' },
  'github-workflows':                { cat: 'ai',         color: '#B870FF', icon: 'workflow' },
  'skill-lifecycle':                 { cat: 'power',      color: '#FE4C25', icon: 'lightning' },
  'suggest-awesome-github-copilot':  { cat: 'ai',         color: '#B870FF', icon: 'robot' },
};

export const CATEGORY_LABELS: Record<string, string> = {
  ai:        'AI',
  docs:      'Documentation',
  power:     'Productivity',
  automation: 'Automation',
  extension: 'Extension',
  dev:       'Developer',
  learn:     'Learning',
};

export const DEFAULT_CATEGORY: CategoryConfig = { cat: 'ai', color: '#B870FF', icon: 'robot' };

export function getCategory(pluginName: string): CategoryConfig {
  return CATEGORIES[pluginName] ?? DEFAULT_CATEGORY;
}
