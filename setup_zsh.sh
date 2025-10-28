#!/bin/bash

set -e

echo "🐚 Setting up Zsh with Prezto..."

# Check if Prezto is already installed
if [[ -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    echo "✓ Prezto is already installed"
else
    echo "📦 Installing Prezto..."
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
fi

# Get the dotfiles directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create symlinks for zsh config files
echo "📁 Creating zsh config symlinks..."
ln -sf "${SCRIPT_DIR}/.zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
ln -sf "${SCRIPT_DIR}/.zpreztorc" "${ZDOTDIR:-$HOME}/.zpreztorc"
ln -sf "${SCRIPT_DIR}/.zprofile" "${ZDOTDIR:-$HOME}/.zprofile"
ln -sf "${SCRIPT_DIR}/.zshenv" "${ZDOTDIR:-$HOME}/.zshenv"

echo "✅ Zsh setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Prezto modules are loaded from .zpreztorc"
