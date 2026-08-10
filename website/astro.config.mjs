import { defineConfig } from 'astro/config';

// Set `base` to match your GitHub Pages deployment path.
// For a custom domain serving at root, use '/'.
// For a project site at github.io/plagueho.copilot/, use '/plagueho.copilot/'.
export default defineConfig({
  output: 'static',
  site: 'https://plagueho.github.io',
  base: '/plagueho.copilot/',
  build: {
    format: 'directory',
  },
});
