#!/bin/zsh
# Git Worktree Manager for Zsh
# Usage:
#   wt              - Show worktree list with fzf
#   wt add <branch> - Create new branch and worktree
#   wt co <branch>  - Checkout existing branch to worktree
#   wt remove <branch> - Remove worktree and branch
#   wt clean        - Remove merged branches and their worktrees
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

    elif [[ "$cmd" == "clean" ]]; then
        # Get current branch
        local current_branch=$(git branch --show-current)

        # Get all merged branches (exclude main, master, and current branch)
        local merged_branches=$(git branch --merged main | grep -v '^\*' | grep -v 'main$' | grep -v 'master$' | grep -v "^[* ]*${current_branch}$" | sed 's/^[ *]*//')

        if [[ -z "$merged_branches" ]]; then
            echo "No merged branches to clean up"
            return 0
        fi

        echo "The following merged branches will be deleted:"
        echo ""

        local branches_to_delete=()
        local worktrees_to_delete=()

        while IFS= read -r branch; do
            if [[ -n "$branch" ]]; then
                branches_to_delete+=("$branch")

                # Check if worktree exists for this branch
                local worktree_info=$(git worktree list | grep "\[$branch\]")
                if [[ -n "$worktree_info" ]]; then
                    local worktree_path=$(echo "$worktree_info" | awk '{print $1}')
                    worktrees_to_delete+=("$worktree_path")
                    echo "  🌳 $branch (worktree: $worktree_path)"
                else
                    echo "  📌 $branch (no worktree)"
                fi
            fi
        done <<< "$merged_branches"

        echo ""
        echo -n "Delete these branches and worktrees? (y/n): "
        read -r confirmation

        if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
            echo "Cancelled"
            return 0
        fi

        echo ""
        local deleted_count=0

        for branch in "${branches_to_delete[@]}"; do
            # Remove worktree if exists
            local worktree_info=$(git worktree list | grep "\[$branch\]")
            if [[ -n "$worktree_info" ]]; then
                local worktree_path=$(echo "$worktree_info" | awk '{print $1}')
                git worktree remove --force "$worktree_path" 2>/dev/null
                if [[ $? -eq 0 ]]; then
                    echo "✓ Removed worktree: $worktree_path"
                fi
            fi

            # Delete branch
            git branch -D "$branch" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "✓ Deleted branch: $branch"
                ((deleted_count++))
            fi
        done

        echo ""
        echo "Cleaned up $deleted_count branch(es)"

    elif [[ "$cmd" == "co" ]]; then
        local branch_input=$2

        if [[ -z "$branch_input" ]]; then
            echo "Usage: wt co <branch>"
            return 1
        fi

        # Check if we're in a git repository
        local project_root=$(git rev-parse --show-toplevel 2>/dev/null)
        if [[ -z "$project_root" ]]; then
            echo "Not in a git repository"
            return 1
        fi

        # Parse branch name (handle origin/branch format)
        local remote_name=""
        local branch_name="$branch_input"

        if [[ "$branch_input" =~ ^([^/]+)/(.+)$ ]]; then
            # Check if it's a remote reference (e.g., origin/feature/branch)
            local potential_remote="${match[1]}"
            if git remote | grep -q "^${potential_remote}$"; then
                remote_name="$potential_remote"
                branch_name="${match[2]}"
            fi
        fi

        # Check if branch is already checked out in a worktree
        local existing_worktree=$(git worktree list | grep "\[$branch_name\]" | awk '{print $1}')
        if [[ -n "$existing_worktree" ]]; then
            echo "Error: Branch '$branch_name' is already checked out at: $existing_worktree"
            return 1
        fi

        local project_name=$(basename "$project_root")
        local parent_dir=$(dirname "$project_root")
        local worktree_path="$parent_dir/${project_name}-${branch_name}"

        # Check if local branch exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            echo "Creating worktree from local branch: $branch_name"
            git worktree add "$worktree_path" "$branch_name"
        else
            # Local branch doesn't exist, try remote
            echo "Local branch not found, checking remote..."

            # Use specified remote or default to origin
            local target_remote="${remote_name:-origin}"

            # Fetch from remote
            echo "Fetching from $target_remote..."
            git fetch "$target_remote" 2>/dev/null

            # Check if remote branch exists
            if git show-ref --verify --quiet "refs/remotes/$target_remote/$branch_name"; then
                echo "Creating worktree from remote branch: $target_remote/$branch_name"
                git worktree add -b "$branch_name" "$worktree_path" --track "$target_remote/$branch_name"
            else
                echo "Error: Branch '$branch_name' not found in local or remote '$target_remote'"
                return 1
            fi
        fi

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
        fi

    else
        echo "Unknown command: $cmd"
        echo "Usage:"
        echo "  wt                 - Show worktree list with fzf (Ctrl+D to delete)"
        echo "  wt add <branch>    - Create new branch and worktree"
        echo "  wt co <branch>     - Checkout existing branch to worktree"
        echo "  wt remove <branch> - Remove worktree and branch"
        echo "  wt clean           - Remove merged branches and their worktrees"
        echo "  wt init            - Create .wt_hook.sh template"
        return 1
    fi
}
