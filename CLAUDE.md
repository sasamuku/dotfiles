# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS setup and configuration management. It contains shell scripts for automated macOS setup, Homebrew package management, and various development tool configurations.

## Setup Commands

### Full macOS Setup (new machine)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/MH4GF/dotfiles/master/setup_macos.sh)"
```

### Dotfiles Symlink Setup Only
```bash
./setup.sh
```

### Claude MCP Servers Setup
```bash
./setup_claude_mcp.sh
```

## Repository Structure

Key files and directories:
- `setup.sh` - Main dotfiles symlink setup script
- `setup_macos.sh` - Complete macOS setup including Homebrew and tools installation
- `setup_claude_mcp.sh` - Sets up MCP servers for Claude Code
- `Brewfile` - Homebrew packages and applications list
- `.zshrc` - Zsh shell configuration with aliases and settings
- `.gitconfig` - Git configuration with custom aliases
- `.config/` - Application configurations (starship, karabiner, gh, git, mise, nvim)
- `.claude/` - Claude-specific settings and commands
- `.serena/` - Serena MCP server configuration

## Development Tools

### Tool Version Management (mise)
This repository uses mise for managing development tool versions:
- Node.js: 22.14.0
- Go: 1.21.2
- Ruby: 3.2.2

### Key Shell Aliases

Git shortcuts:
- `g` - Git status or pass-through to git commands
- `gp` - Push current branch to origin
- `gpf` - Force push with lease to origin
- `co` - Interactive branch checkout with peco
- `com` - Checkout main/master, pull, and clean merged branches
- `comw` - Same as `com` but also cleans up worktrees

Development:
- `ghql` - Interactive repository navigation using ghq and peco
- `dc` - Docker compose shortcut
- `nf` - Open Neovim with file finder
- `ng` - Open Neovim with live grep
- `devc` - Open VS Code devcontainer

## Git Configuration

The repository includes advanced git aliases for:
- Worktree management (`wa`, `war`, `wt`)
- Branch cleanup (`com`, `comw`)
- Interactive branch selection using peco

## MCP Server Configuration

The repository includes setup for three MCP servers:
1. **playwright** - Browser automation capabilities
2. **context7** - Documentation retrieval
3. **serena** - Code analysis and semantic search

These are automatically configured via `setup_claude_mcp.sh`.

## Manual Post-Setup Steps

After running setup scripts:
1. Sign in to 1Password
2. Configure AWS credentials if needed
3. Copy `.gitconfig.local.sample` to `.gitconfig.local` for personal git settings
4. Copy `.zsh_secrets.example` to `.zsh_secrets` for private environment variables
5. Restart computer for all macOS preferences to take effect