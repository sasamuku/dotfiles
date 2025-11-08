#!/bin/zsh
# Git Worktree Manager for Zsh
# Usage:
#   wt              - Show worktree list with fzf
#   wt add <branch> - Create new branch and worktree
#   wt remove <branch> - Remove worktree and branch
#   wt pr <PR-URL>  - Create worktree from GitHub PR
#   wt init         - Create .wt_hook.sh template

function wt() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        # Show worktree list with fzf
        local selected=$(git worktree list | fzf \
            --preview-window="right:70%:wrap" \
            --preview='
                worktree_path=$(echo {} | awk "{print \$1}")
                branch=$(echo {} | sed "s/.*\[//" | sed "s/\]//")

                echo "┌──────────────────────────────────────────────────┐"
                echo "│ 🌳 Branch: $branch"
                echo "└──────────────────────────────────────────────────┘"
                echo ""
                echo "📁 Path: $worktree_path"
                echo ""
                echo "📝 Changed files:"
                echo "───────────────────────────────────────────────────"
                changes=$(git -C "$worktree_path" status --porcelain 2>/dev/null)
                if [ -z "$changes" ]; then
                    echo "  ✨ Working tree clean"
                else
                    echo "$changes" | head -10 | while read line; do
                        file_status=$(echo "$line" | cut -c1-2)
                        file_name=$(echo "$line" | cut -c4-)
                        case "$file_status" in
                            "M "*) echo "  🔧 Modified: $file_name";;
                            "A "*) echo "  ➕ Added: $file_name";;
                            "D "*) echo "  ➖ Deleted: $file_name";;
                            "??"*) echo "  ❓ Untracked: $file_name";;
                            *) echo "  📄 $line";;
                        esac
                    done
                fi
                echo ""
                echo "📜 Recent commits:"
                echo "───────────────────────────────────────────────────"
                git -C "$worktree_path" log --oneline --color=always -10 2>/dev/null | sed "s/^/  /"
            ' \
            --bind='ctrl-d:execute-silent(
                worktree_path=$(echo {} | awk "{print \$1}")
                branch=$(echo {} | sed "s/.*\[//" | sed "s/\]//")

                # Prevent deletion of main branch
                if [[ "$branch" == "main" || "$branch" == "master" ]]; then
                    echo "Cannot delete main/master branch" >&2
                    exit 1
                fi

                # Remove worktree and branch
                git worktree remove --force "$worktree_path" 2>/dev/null
                git branch -D "$branch" 2>/dev/null
            )+reload(git worktree list)' \
            --header="🌲 Git Worktree Manager | Enter: navigate | Ctrl+D: delete" \
            --border \
            --height=80% \
            --layout=reverse \
            --prompt="🔍 " | awk '{print $1}'
        )

        if [[ -n "$selected" ]]; then
            cd "$selected"
        fi

    elif [[ "$cmd" == "add" ]]; then
        local branch_name=$2

        if [[ -z "$branch_name" ]]; then
            echo "Usage: wt add <branch_name>"
            return 1
        fi

        # Get project root and create worktree path
        local project_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ -z "$project_root" ]]; then
            echo "Not in a git repository"
            return 1
        fi

        local project_name=$(basename "$project_root")
        local parent_dir=$(dirname "$project_root")
        local worktree_path="$parent_dir/${project_name}-${branch_name}"

        # Create new branch and worktree
        git worktree add -b "$branch_name" "$worktree_path"

        if [[ $? -eq 0 ]]; then
            echo "Created worktree at: $worktree_path"
            echo "Branch: $branch_name"

            # Store project root before changing directory
            local project_root=$(git rev-parse --show-toplevel)

            cd "$worktree_path"

            # Execute .wt_hook.sh if it exists in the project root
            if [[ -f "$project_root/.wt_hook.sh" ]]; then
                echo "Executing .wt_hook.sh..."
                export WT_WORKTREE_PATH="$worktree_path"
                export WT_BRANCH_NAME="$branch_name"
                export WT_PROJECT_ROOT="$project_root"
                source "$project_root/.wt_hook.sh"
                unset WT_WORKTREE_PATH
                unset WT_BRANCH_NAME
                unset WT_PROJECT_ROOT
            fi
        fi

    elif [[ "$cmd" == "remove" ]]; then
        local branch_name=$2

        if [[ -z "$branch_name" ]]; then
            echo "Usage: wt remove <branch_name>"
            return 1
        fi

        # Find worktree path by branch name
        local worktree_info=$(git worktree list | grep "\[$branch_name\]")

        if [[ -z "$worktree_info" ]]; then
            echo "No worktree found for branch: $branch_name"
            return 1
        fi

        local worktree_path=$(echo "$worktree_info" | awk '{print $1}')

        # Remove worktree
        git worktree remove --force "$worktree_path"

        if [[ $? -eq 0 ]]; then
            # Delete branch
            git branch -D "$branch_name"
            echo "Removed worktree and branch: $branch_name"
        fi

    elif [[ "$cmd" == "init" ]]; then
        # Check if .wt_hook.sh already exists
        if [[ -f ".wt_hook.sh" ]]; then
            echo ".wt_hook.sh already exists"
            return 1
        fi

        # Create .wt_hook.sh with copy template
        cat > .wt_hook.sh << 'EOF'
#!/bin/bash
# .wt_hook.sh - Executed after 'wt add' command in worktree directory
# Available variables:
# - $WT_WORKTREE_PATH: Path to the new worktree (current directory)
# - $WT_BRANCH_NAME: Name of the branch
# - $WT_PROJECT_ROOT: Path to the original project root

# Files and directories to copy from project root to worktree directory
# Add or remove file/directory names as needed
copy_items=(".env" ".claude")

for item in "${copy_items[@]}"; do
    if [[ -f "$WT_PROJECT_ROOT/$item" ]]; then
        # Copy file
        cp "$WT_PROJECT_ROOT/$item" "$item"
        echo "Copied file $item to worktree"
    elif [[ -d "$WT_PROJECT_ROOT/$item" ]]; then
        # Copy directory recursively
        cp -r "$WT_PROJECT_ROOT/$item" "$item"
        echo "Copied directory $item to worktree"
    fi
done

# Example: Install dependencies
# npm install

# Add your custom initialization commands here
EOF

        chmod +x .wt_hook.sh
        echo "Created .wt_hook.sh template"

    elif [[ "$cmd" == "pr" ]]; then
        local pr_input=$2

        if [[ -z "$pr_input" ]]; then
            echo "Usage: wt pr <PR-number|PR-URL>"
            return 1
        fi

        # Check if gh CLI is available
        if ! command -v gh &> /dev/null; then
            echo "Error: gh CLI is not installed"
            echo "Install it with: brew install gh"
            return 1
        fi

        # Get project root
        local project_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ -z "$project_root" ]]; then
            echo "Not in a git repository"
            return 1
        fi

        # Extract PR number from URL or use as-is
        local pr_number=$(echo "$pr_input" | grep -oE '[0-9]+$')
        if [[ -z "$pr_number" ]]; then
            echo "Error: Could not extract PR number from: $pr_input"
            return 1
        fi

        echo "Fetching PR #$pr_number information..."

        # Get PR branch name
        local head_ref=$(gh pr view "$pr_number" --json headRefName -q .headRefName 2>/dev/null)
        if [[ -z "$head_ref" ]]; then
            echo "Error: Could not fetch PR #$pr_number"
            echo "Make sure the PR exists and you have access to it"
            return 1
        fi

        local branch_name="pr-${pr_number}"

        echo "PR branch: $head_ref"
        echo "Creating worktree for PR #$pr_number: $branch_name"

        # Check if PR branch already exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            # Check if the branch is checked out in any worktree
            local branch_worktree=$(git worktree list | grep "\[$branch_name\]" | awk '{print $1}')
            if [[ -n "$branch_worktree" ]]; then
                echo "Error: Branch $branch_name is currently checked out at: $branch_worktree"
                echo "Please switch to a different branch or remove the worktree first:"
                echo "  cd $branch_worktree && git checkout main"
                echo "  or"
                echo "  wt remove $branch_name"
                return 1
            fi
            echo "Removing existing PR branch: $branch_name"
            git branch -D "$branch_name" 2>/dev/null
        fi

        # Fetch the PR branch from remote
        echo "Fetching remote branch..."
        git fetch origin "pull/$pr_number/head:$branch_name" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to fetch PR #$pr_number"
            return 1
        fi

        # Create worktree from the fetched branch
        local project_name=$(basename "$project_root")
        local parent_dir=$(dirname "$project_root")
        local worktree_path="$parent_dir/${project_name}-${branch_name}"

        git worktree add "$worktree_path" "$branch_name"

        if [[ $? -eq 0 ]]; then
            echo "Created worktree at: $worktree_path"
            echo "Branch: $branch_name"

            cd "$worktree_path"

            # Execute .wt_hook.sh if it exists in the project root
            if [[ -f "$project_root/.wt_hook.sh" ]]; then
                echo "Executing .wt_hook.sh..."
                export WT_WORKTREE_PATH="$worktree_path"
                export WT_BRANCH_NAME="$branch_name"
                export WT_PROJECT_ROOT="$project_root"
                source "$project_root/.wt_hook.sh"
                unset WT_WORKTREE_PATH
                unset WT_BRANCH_NAME
                unset WT_PROJECT_ROOT
            fi

            echo ""
            echo "✅ Worktree ready for PR #$pr_number"
        fi

    else
        echo "Unknown command: $cmd"
        echo "Usage:"
        echo "  wt                 - Show worktree list with fzf (Ctrl+D to delete)"
        echo "  wt add <branch>    - Create new branch and worktree"
        echo "  wt remove <branch> - Remove worktree and branch"
        echo "  wt pr <PR-URL>     - Create worktree from GitHub PR"
        echo "  wt init            - Create .wt_hook.sh template"
        return 1
    fi
}
