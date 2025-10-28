#!/bin/sh

# Dotfiles Setup Script
# This script creates symlinks for development tools configuration

echo "🔧 Setting up dotfiles..."

# Zsh setup
echo "🐚 Setting up Zsh..."
$(dirname ${0})/setup_zsh.sh

echo ""

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

# Claude MCP setup
echo "🔌 Setting up Claude MCP servers..."
$(dirname ${0})/setup_claude_mcp.sh

echo "✅ Claude Code setup completed!"
echo ""
echo "📝 Next steps:"
echo "  1. Edit .serena/serena_config.yml to add your project paths"
echo "  2. Restart Claude Code to apply the new settings"
