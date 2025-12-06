# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS setup and configuration management. It contains shell scripts for automated macOS setup, Homebrew package management, and various development tool configurations.

## Setup Commands

### Full Setup (new machine)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/sasamuku/dotfiles/master/setup.sh)"
```

### Script Dependency Tree
```
setup.sh (Main wrapper)
├── setup_brew.sh (Homebrew + packages)
├── setup_zsh.sh (Zsh + sheldon)
├── setup_dotfiles.sh (Dotfiles: Git, Claude, Serena, Neovim)
│   └── setup_claude_mcp.sh (MCP servers)
└── setup_macos.sh (macOS preferences)
```

All setup scripts can be run independently.

## Repository Structure

### Configuration Files
- `Brewfile` - Homebrew packages, casks, VS Code extensions
- `.zshrc`, `.zprofile`, `.zshenv` - Zsh configs
- `.config/sheldon/plugins.toml` - sheldon plugin manager config
- `.config/starship.toml` - Starship prompt config
- `.config/mise/config.toml` - mise version manager (global)
- `.gitconfig` - Git aliases and settings
- `.gitconfig.local.sample` → `~/.gitconfig.local` (personal git settings)
- `.zsh_secrets.example` → `~/.zsh_secrets` (private env vars)
- `.config/nvim/` - Neovim (Lua)
- `.config/wezterm/` - WezTerm terminal emulator
- `.claude/` - Claude Code settings
- `.serena/` - Serena MCP config

## Development Tools

### Shell Environment
- **Zsh** + **sheldon** (fast Rust-based plugin manager)
- Plugins: completion, syntax-highlighting, autosuggestions, history-substring-search
- **Starship** prompt (fast, customizable, cross-shell)
- **peco** keybindings: `Ctrl+R` (history), `Ctrl+G` (directory)
- **mise** for tool versions: Node.js 25.2.1, Go 1.23.2, Ruby 3.2.2

### Key Aliases
- `.zshrc`: `ls`, `showz`, `editz`, `sourcez`, `be`, `ghql`, `dc`, `nf`, `ng`, `devc`
- `.gitconfig`: `st`, `co`, `br`, `cm`, `pr`, `lg`, `wa`, `wl`, `wr` (see Git Configuration)

## Git Configuration

`.gitconfig` includes shortcuts, color schemes, and local config include.
Personal settings (name, email) → `~/.gitconfig.local` (copy from `.gitconfig.local.sample`)

### Git Worktree Manager (`wt`)

Custom Zsh function for managing git worktrees efficiently:

**Commands:**
- `wt` - Show worktree list with fzf; press `Ctrl+D` to delete selected worktree
- `wt add <branch>` - Create new branch and worktree
- `wt remove <branch>` - Remove worktree and delete branch
- `wt clean` - Batch remove merged branches and their worktrees (interactive confirmation)
- `wt init` - Create `.wt_hook.sh` template for custom setup (e.g., copy `.env`, install deps)

**Location:** `.config/zsh/functions/wt.zsh`

## MCP Servers

Configured via `setup_claude_mcp.sh`: **playwright**, **context7**, **serena**

## Post-Setup Steps

1. Sign in to 1Password
2. Copy `.gitconfig.local.sample` → `~/.gitconfig.local` (personal git settings)
3. Copy `.zsh_secrets.example` → `~/.zsh_secrets` (private env vars)
4. Copy `.serena/serena_config.yml.sample` → `~/.serena/serena_config.yml` (Serena project paths)
5. Restart computer
