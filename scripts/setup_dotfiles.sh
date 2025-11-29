#!/bin/sh

# Dotfiles Setup Script
# This script creates symlinks for development tools configuration

echo "🔧 Setting up dotfiles..."

# Git configuration
echo "📝 Setting up Git configuration..."
DOTFILES_DIR=$(realpath $(dirname ${0})/..)
ln -sfn ${DOTFILES_DIR}/.gitconfig ~/.gitconfig
ln -sfn ${DOTFILES_DIR}/.gitignore ~/.gitignore
ln -sfn ${DOTFILES_DIR}/.ignore ~/.ignore
if [ ! -f ~/.gitconfig.local ]; then
  echo "  ⚠️  Note: Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
fi

# Claude settings
echo "🔧 Setting up Claude Code configuration..."
echo "📁 Creating Claude settings symlinks..."
mkdir -p ~/.claude
ln -sfn ${DOTFILES_DIR}/.claude/commands ~/.claude/commands
ln -sfn ${DOTFILES_DIR}/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sfn ${DOTFILES_DIR}/.claude/settings.json ~/.claude/settings.json
ln -sfn ${DOTFILES_DIR}/.claude/hooks ~/.claude/hooks
ln -sfn ${DOTFILES_DIR}/.claude/agents ~/.claude/agents

# Serena config
if [ ! -f ~/.serena/serena_config.yml ]; then
  echo "  ⚠️  Note: Copy .serena/serena_config.yml.sample to ~/.serena/serena_config.yml for Serena settings"
fi

# Neovim config
echo "📁 Creating Neovim config symlink..."
mkdir -p ~/.config/nvim
ln -sfn ${DOTFILES_DIR}/.config/nvim/init.lua ~/.config/nvim/init.lua

# WezTerm config
echo "📁 Creating WezTerm config symlink..."
mkdir -p ~/.config/wezterm
ln -sfn ${DOTFILES_DIR}/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua

# Starship config
echo "📁 Creating Starship config symlink..."
mkdir -p ~/.config
ln -sfn ${DOTFILES_DIR}/.config/starship.toml ~/.config/starship.toml

# Zsh functions
echo "📁 Creating Zsh functions symlink..."
mkdir -p ~/.config/zsh/functions
ln -sfn ${DOTFILES_DIR}/.config/zsh/functions/wt.zsh ~/.config/zsh/functions/wt.zsh
ln -sfn ${DOTFILES_DIR}/.config/zsh/functions/ghq.zsh ~/.config/zsh/functions/ghq.zsh

# Cursor config
echo "📁 Creating Cursor config symlinks..."
mkdir -p ~/Library/Application\ Support/Cursor/User
ln -sfn ${DOTFILES_DIR}/.config/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -sfn ${DOTFILES_DIR}/.config/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json

# Claude MCP setup
echo "🔌 Setting up Claude MCP servers..."
"$(dirname "${0}")/setup_claude_mcp.sh"

echo "✅ Dotfiles setup completed!"
echo ""
echo "📝 Next steps:"
echo "  1. Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
echo "  2. Copy .zsh_secrets.example to ~/.zsh_secrets for private environment variables"
echo "  3. Copy .serena/serena_config.yml.sample to ~/.serena/serena_config.yml and add your project paths"
echo "  4. Restart Claude Code and your shell to apply the new settings"
