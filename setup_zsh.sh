#!/bin/bash

set -e

# Get the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create symlinks for zsh config files
echo "📁 Creating zsh config symlinks..."
ln -sf "${SCRIPT_DIR}/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
ln -sf "${SCRIPT_DIR}/.zprofile" "${ZDOTDIR:-$HOME}/.zprofile"
ln -sf "${SCRIPT_DIR}/.zshenv" "${ZDOTDIR:-$HOME}/.zshenv"

# Create sheldon config directory and symlink
echo "📁 Creating sheldon config symlink..."
mkdir -p "${HOME}/.config"
ln -sf "${SCRIPT_DIR}/.config/sheldon" "${HOME}/.config/sheldon"

# Install sheldon plugins
echo "📦 Installing sheldon plugins..."
if command -v sheldon &> /dev/null; then
    sheldon lock --update
    echo "✅ Sheldon plugins installed"
else
    echo "⚠️  sheldon not found. Install it with: brew install sheldon"
fi

echo "✅ Zsh setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Plugins are managed by sheldon (.config/sheldon/plugins.toml)"
