# Dotfiles Best Practices Guide

Compiled from [dotfiles.github.io](https://dotfiles.github.io/) tutorials.

## Why a Dotfiles Repo?

- **Disaster recovery** — reinstall in minutes, not hours.
- **Consistency** — identical environment across devices.
- **Sharing** — learn from, and contribute to, the community.
- **History** — Git tracks every config change.

## Repository Organization Styles

### Flat Layout

All files at repo root. Simple, works for < 15 files.

### Topical Layout

Grouped by tool (`git/`, `shell/`, `editor/`). Recommended for larger sets.

### Git Bare Repository

Bare repo with work tree set to `$HOME`. No symlinks needed but more complex.
Source: Nicola Paolucci (Atlassian).

### GNU Stow

Uses `stow` to auto-symlink each subdirectory as a package.
Source: Dreams of Autonomy.

## Common Dotfile Categories

| Category | Files | Purpose |
|----------|-------|---------|
| Shell | `.bashrc`, `.bash_profile`, `.zshrc`, `.zprofile`, `.profile`, `.aliases`, `.functions` | Shell configuration, aliases, functions, PATH |
| Git | `.gitconfig`, `.gitignore_global`, `.gitattributes`, `.gitmessage` | Git identity, aliases, diff/merge tools, global ignores |
| Editor | `.vimrc`, `.editorconfig`, `.nanorc` | Editor preferences, indentation, formatting |
| SSH | `.ssh/config` | Host aliases, proxy settings (never commit keys) |
| Terminal | `.tmux.conf`, `.screenrc`, `.wezterm.lua` | Terminal multiplexer and emulator settings |
| Package managers | `Brewfile`, `.npmrc`, `.yarnrc` | Declarative package lists |
| OS preferences | `.macos` (macOS defaults script), `.Xresources` | System-level preferences |
| Prompt | `.p10k.zsh`, `.starship.toml` | Shell prompt themes |
| Language runtimes | `.gemrc`, `.pylintrc`, `.prettierrc`, `.eslintrc.*` | Linter, formatter, runtime configs |

## Bootstrap Script Best Practices

1. **Idempotent** — safe to run multiple times.
2. **Backup first** — move existing files to timestamped backup dir.
3. **Dry-run mode** — `--dry-run` flag to preview without changes.
4. **OS detection** — branch on `uname` or `$PSVersionTable`.
5. **Clear output** — print each link, backup, or skip.
6. **Package install** — optionally run `brew bundle` or equivalent.
7. **Source configs** — reload shell to apply changes.

## Security Considerations

- **Never commit SSH private keys** (`id_rsa`, `id_ed25519`, etc.).
- **Never commit API tokens**, passwords, or secrets.
- **Sanitize paths** — replace machine-specific paths with `$HOME` or
  environment variable references.
- **Review `.gitconfig`** — email addresses are fine but confirm with the user.
- **Use `.gitignore`** in the dotfiles repo to prevent accidental secrets.

## Maintenance

- Add new tools to `Brewfile` or package list.
- Update dotfiles in repo, not just locally.
- Prune configs for tools no longer used.
- Use branches for divergent machines.

## Key References

- [dotfiles.github.io](https://dotfiles.github.io/)
- [Dries Vints — Getting Started](https://driesvints.com/blog/getting-started-with-dotfiles/)
- [Lars Kappert — Getting Started](https://www.webpro.nl/articles/getting-started-with-dotfiles)
- [Awesome dotfiles](https://github.com/webpro/awesome-dotfiles)
