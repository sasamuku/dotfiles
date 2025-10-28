#!/bin/bash

set -e

echo "🍺 Starting Homebrew Setup..."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is only for macOS!"
    exit 1
fi

# Check for Xcode Command Line Tools
echo "📦 Checking Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    echo "Xcode Command Line Tools not found. Installing..."
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
else
    echo "Homebrew is already installed"
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
    exit 1
fi

echo "✅ Homebrew setup complete!"
