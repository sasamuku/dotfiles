# dotfiles

Personal macOS dotfiles and setup automation.

## Quick Start

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/sasamuku/dotfiles/master/setup.sh)"
```

## What's Included

- **Shell**: Zsh + sheldon + Starship
- **Package Manager**: Homebrew
- **Editor**: Neovim
- **Terminal**: WezTerm
- **Version Manager**: mise (Node.js, Go, Ruby)
- **Git**: Custom aliases and worktree manager

## Post-Setup

1. Copy `.gitconfig.local.sample` → `~/.gitconfig.local`
2. Copy `.zsh_secrets.example` → `~/.zsh_secrets`
3. Copy `.serena/serena_config.yml.sample` → `~/.serena/serena_config.yml`

See [CLAUDE.md](CLAUDE.md) for detailed documentation.