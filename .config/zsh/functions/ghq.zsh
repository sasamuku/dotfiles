#!/bin/zsh
# ghq Command Wrapper with fzf Navigation
# Usage:
#   ghq           - Jump to a ghq-managed repository with fzf preview
#   ghq <args>    - Execute original ghq command with arguments

function ghq() {
    # If arguments are provided, use original ghq command
    if [ $# -gt 0 ]; then
        command ghq "$@"
        return
    fi

    # No arguments: show repository list with fzf
    local selected=$(command ghq list -p | fzf \
        --preview-window="right:60%:wrap" \
        --preview='
            repo_path={}

            echo "┌──────────────────────────────────────────────────┐"
            echo "│ 📦 Repository: $(basename {})"
            echo "└──────────────────────────────────────────────────┘"
            echo ""
            echo "📁 Path: $repo_path"
            echo ""

            # Show README.md if exists
            if [ -f "$repo_path/README.md" ]; then
                echo "📖 README.md:"
                echo "───────────────────────────────────────────────────"
                if command -v bat > /dev/null 2>&1; then
                    bat --style=plain --color=always "$repo_path/README.md" 2>/dev/null | head -50
                else
                    cat "$repo_path/README.md" 2>/dev/null | head -50
                fi
            else
                echo "📄 Files:"
                echo "───────────────────────────────────────────────────"
                ls -la "$repo_path" 2>/dev/null | head -20 | sed "s/^/  /"
            fi
        ' \
        --header="📚 ghq Repository Navigator | Press Enter to navigate" \
        --border \
        --height=80% \
        --layout=reverse \
        --prompt="🔍 "
    )

    if [[ -n "$selected" ]]; then
        cd "$selected"
        echo "Moved to: $selected"
    fi
}
