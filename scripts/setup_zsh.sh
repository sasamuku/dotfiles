#!/bin/bash

set -e

# Get the dotfiles directory (parent of scripts/)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create symlinks for zsh config files
echo "📁 Creating zsh config symlinks..."
ln -sf "${DOTFILES_DIR}/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
ln -sf "${DOTFILES_DIR}/.zprofile" "${ZDOTDIR:-$HOME}/.zprofile"
ln -sf "${DOTFILES_DIR}/.zshenv" "${ZDOTDIR:-$HOME}/.zshenv"

# Create sheldon config directory and symlink
echo "📁 Creating sheldon config symlink..."
mkdir -p "${HOME}/.config"
ln -sf "${DOTFILES_DIR}/.config/sheldon" "${HOME}/.config/sheldon"

# Install sheldon plugins
echo "📦 Installing sheldon plugins..."
if command -v sheldon &> /dev/null; then
    sheldon lock --update
    echo "✅ Sheldon plugins installed"
else
    echo "⚠️  sheldon not found. Install it with: brew install sheldon"
fi

# Setup fzf shell integration
echo "🔍 Setting up fzf shell integration..."
if command -v brew &> /dev/null && brew list fzf &> /dev/null; then
    FZF_INSTALL_SCRIPT="$(brew --prefix)/opt/fzf/install"
    if [[ -f "$FZF_INSTALL_SCRIPT" ]]; then
        # Run fzf install script non-interactively
        "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc
        echo "✅ fzf shell integration configured"
    fi
else
    echo "⚠️  fzf not found. Install it with: brew install fzf"
fi

echo "✅ Zsh setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Plugins are managed by sheldon (.config/sheldon/plugins.toml)"
