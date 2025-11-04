#!/bin/sh

# Dotfiles Setup Script
# This script creates symlinks for development tools configuration

echo "🔧 Setting up dotfiles..."

# Git configuration
echo "📝 Setting up Git configuration..."
ln -sfn $(realpath $(dirname ${0}))/.gitconfig ~/.gitconfig
ln -sfn $(realpath $(dirname ${0}))/.gitignore ~/.gitignore
if [ ! -f ~/.gitconfig.local ]; then
  echo "  ⚠️  Note: Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
fi

# Claude settings
echo "🔧 Setting up Claude Code configuration..."
echo "📁 Creating Claude settings symlinks..."
mkdir -p ~/.claude
ln -sfn $(realpath $(dirname ${0}))/.claude/commands ~/.claude/commands
ln -sfn $(realpath $(dirname ${0}))/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sfn $(realpath $(dirname ${0}))/.claude/settings.json ~/.claude/settings.json
ln -sfn $(realpath $(dirname ${0}))/.claude/hooks ~/.claude/hooks

# Serena config
if [ ! -f ~/.serena/serena_config.yml ]; then
  echo "  ⚠️  Note: Copy .serena/serena_config.yml.sample to ~/.serena/serena_config.yml for Serena settings"
fi

# Neovim config
echo "📁 Creating Neovim config symlink..."
mkdir -p ~/.config/nvim
ln -sfn $(realpath $(dirname ${0}))/.config/nvim/init.lua ~/.config/nvim/init.lua

# WezTerm config
echo "📁 Creating WezTerm config symlink..."
mkdir -p ~/.config/wezterm
ln -sfn $(realpath $(dirname ${0}))/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua

# Starship config
echo "📁 Creating Starship config symlink..."
mkdir -p ~/.config
ln -sfn $(realpath $(dirname ${0}))/.config/starship.toml ~/.config/starship.toml

# Zsh functions
echo "📁 Creating Zsh functions symlink..."
mkdir -p ~/.config/zsh/functions
ln -sfn $(realpath $(dirname ${0}))/.config/zsh/functions/wt.zsh ~/.config/zsh/functions/wt.zsh

# Cursor config
echo "📁 Creating Cursor config symlinks..."
mkdir -p ~/Library/Application\ Support/Cursor/User
ln -sfn $(realpath $(dirname ${0}))/.config/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
ln -sfn $(realpath $(dirname ${0}))/.config/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json

# Claude MCP setup
echo "🔌 Setting up Claude MCP servers..."
$(dirname ${0})/setup_claude_mcp.sh

echo "✅ Dotfiles setup completed!"
echo ""
echo "📝 Next steps:"
echo "  1. Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
echo "  2. Copy .zsh_secrets.example to ~/.zsh_secrets for private environment variables"
echo "  3. Copy .serena/serena_config.yml.sample to ~/.serena/serena_config.yml and add your project paths"
echo "  4. Restart Claude Code and your shell to apply the new settings"
