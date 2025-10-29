#!/bin/sh

# Dotfiles Setup Script
# This script creates symlinks for development tools configuration

echo "🔧 Setting up dotfiles..."

# Git configuration
echo "📝 Setting up Git configuration..."
ln -sf $(realpath $(dirname ${0}))/.gitconfig ~/.gitconfig
if [ ! -f ~/.gitconfig.local ]; then
  echo "  ⚠️  Note: Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
fi

# Claude settings
echo "🔧 Setting up Claude Code configuration..."
echo "📁 Creating Claude settings symlinks..."
mkdir -p ~/.claude
ln -sf $(realpath $(dirname ${0}))/.claude/commands ~/.claude/commands
ln -sf $(realpath $(dirname ${0}))/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf $(realpath $(dirname ${0}))/.claude/settings.json ~/.claude/settings.json
ln -sf $(realpath $(dirname ${0}))/.claude/hooks ~/.claude/hooks

# Serena config
echo "📁 Creating Serena config symlink..."
mkdir -p ~/.serena
ln -sf $(realpath $(dirname ${0}))/.serena/serena_config.yml ~/.serena/serena_config.yml

# Neovim config
echo "📁 Creating Neovim config symlink..."
mkdir -p ~/.config/nvim
ln -sf $(realpath $(dirname ${0}))/.config/nvim/init.lua ~/.config/nvim/init.lua

# WezTerm config
echo "📁 Creating WezTerm config symlink..."
mkdir -p ~/.config/wezterm
ln -sf $(realpath $(dirname ${0}))/.config/wezterm/wezterm.lua ~/.config/wezterm/wezterm.lua

# Starship config
echo "📁 Creating Starship config symlink..."
mkdir -p ~/.config
ln -sf $(realpath $(dirname ${0}))/.config/starship.toml ~/.config/starship.toml

# Claude MCP setup
echo "🔌 Setting up Claude MCP servers..."
$(dirname ${0})/setup_claude_mcp.sh

echo "✅ Dotfiles setup completed!"
echo ""
echo "📝 Next steps:"
echo "  1. Copy .gitconfig.local.sample to ~/.gitconfig.local for personal git settings"
echo "  2. Copy .zsh_secrets.example to ~/.zsh_secrets for private environment variables"
echo "  3. Edit .serena/serena_config.yml to add your project paths"
echo "  4. Restart Claude Code and your shell to apply the new settings"
