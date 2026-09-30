#!/bin/bash

# Main Setup Script
# This script orchestrates all setup scripts in the correct order

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting complete macOS setup..."
echo ""

# 1. Homebrew and packages
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 1/4: Homebrew and Packages"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/setup_brew.sh"
echo ""

# 2. Zsh configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐚 Step 2/4: Zsh and Sheldon"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/setup_zsh.sh"
echo ""

# 3. Dotfiles (Claude, Codex, Neovim)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Step 3/4: Dotfiles (Claude, Codex, Neovim)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/setup_dotfiles.sh"
echo ""

# 4. macOS system preferences
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚙️  Step 4/4: macOS System Preferences"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
"${SCRIPT_DIR}/setup_macos.sh"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Complete setup finished!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📝 Manual steps required:"
echo "  1. Sign in to 1Password and other apps"
echo "  2. Copy .gitconfig.local.sample to .gitconfig.local for personal git settings"
echo "  3. Copy .zsh_secrets.example to .zsh_secrets for private environment variables"
echo "  4. Restart your computer for all changes to take effect"
echo ""
