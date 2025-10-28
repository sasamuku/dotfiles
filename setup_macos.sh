#!/bin/bash

set -e

echo "🍎 Starting macOS Setup..."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is only for macOS!"
    exit 1
fi

# Install Xcode Command Line Tools
echo "📦 Installing Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    xcode-select --install
    echo "Please complete Xcode Command Line Tools installation and run this script again."
    exit 1
fi

# Install Homebrew
echo "🍺 Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# Update Homebrew
echo "🔄 Updating Homebrew..."
brew update
brew upgrade

# Install packages from local Brewfile
echo "📦 Installing packages from Brewfile..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/Brewfile" ]]; then
    brew bundle --file="${SCRIPT_DIR}/Brewfile"
else
    echo "Warning: Brewfile not found at ${SCRIPT_DIR}/Brewfile"
fi

# Run dotfiles setup
echo "📥 Setting up dotfiles..."
"${SCRIPT_DIR}/setup.sh"

# macOS System Preferences
echo "⚙️  Configuring macOS preferences..."

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Show file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Enable key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show battery percentage in menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for all Dock items
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Make Dock icons of hidden applications translucent
defaults write com.apple.dock showhidden -bool true

# Don't show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Restart affected applications
echo "🔄 Restarting affected applications..."
killall Finder || true
killall Dock || true
killall SystemUIServer || true

echo "✅ macOS setup complete!"
echo ""
echo "📌 Manual steps required:"
echo "1. Sign in to 1Password and other apps"
echo "2. Restart your computer for all changes to take effect"
