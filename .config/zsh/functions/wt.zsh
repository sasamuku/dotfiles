#!/bin/zsh
# Git Worktree Manager for Zsh
# Usage:
#   wt              - Show worktree list with fzf
#   wt add <branch> - Create new branch and worktree
#   wt co <branch>  - Checkout existing branch to worktree
#   wt remove [-D] <branch> - Remove worktree and branch (-D: force)
#   wt clean        - Remove merged branches and their worktrees
#   wt init         - Create .wt_hook.sh template

# NUL-delimited paths; an optional branch name is matched literally.
function _wt_paths() {
    local record worktree_path
    while IFS= read -r -d '' record; do
        case "$record" in
            'worktree '*)
                worktree_path=${record#worktree }
                [[ -n "$1" ]] || printf '%s\0' "$worktree_path"
                ;;
            "branch refs/heads/$1")
                printf '%s\0' "$worktree_path"
                return 0
                ;;
        esac
    done < <(git worktree list --porcelain -z)
    [[ -z "$1" ]]
}

function _wt_setup() {
    local project_root=$1 worktree_path=$2 branch_name=$3
    if [[ -f "$project_root/.wt_hook.sh" ]]; then
        echo "Executing .wt_hook.sh..." >&2
        WT_WORKTREE_PATH="$worktree_path" WT_BRANCH_NAME="$branch_name" WT_PROJECT_ROOT="$project_root" \
            bash -e -o pipefail "$project_root/.wt_hook.sh" || {
                echo "Initialization failed; worktree retained at: $worktree_path" >&2
                return 1
            }
    fi
    echo "Created worktree at: $worktree_path"
    echo "Branch: $branch_name"
}

function wt() {
    local cmd=$1

    if [[ -z "$cmd" ]]; then
        local entry branch_name
        local -a selection
        while true; do
            selection=()
            while IFS= read -r -d '' entry; do
                selection+=("$entry")
            done < <(_wt_paths | fzf --read0 --print0 --expect=ctrl-d \
                --preview-window="right:70%:wrap" \
                --preview='
                worktree_path={}
                branch=$(git -C "$worktree_path" branch --show-current)

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
                --header="Git Worktree Manager | Enter: navigate | Ctrl+D: delete clean worktree" \
                --border --height=80% --layout=reverse --prompt="🌲 ")
            (( ${#selection} >= 2 )) || return 0
            if [[ "${selection[1]}" != "ctrl-d" ]]; then
                cd -- "${selection[2]}"
                return $?
            fi
            branch_name=$(git -C "${selection[2]}" branch --show-current) || return 1
            if [[ -z "$branch_name" ]]; then
                echo "Cannot delete a detached worktree from the picker" >&2
                return 1
            fi
            wt remove "$branch_name" || return $?
        done

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
        local safe_name=${branch_name//\//-}
        local worktree_path="$parent_dir/${project_name}-${safe_name}"

        git worktree add -b "$branch_name" "$worktree_path" || return $?
        cd -- "$worktree_path" || return $?
        _wt_setup "$project_root" "$worktree_path" "$branch_name"

    elif [[ "$cmd" == "remove" ]]; then
        shift
        local branch_option=-d
        local -a remove_options=()
        if [[ "$1" == -D ]]; then
            remove_options=(--force)
            branch_option=-D
            shift
        fi
        if (( $# != 1 )) || [[ -z "$1" || "$1" == -* ]]; then
            echo "Usage: wt remove [-D] <branch_name>"
            return 1
        fi
        local branch_name=$1

        if [[ "$branch_name" == main || "$branch_name" == master ]]; then
            echo "Cannot delete main/master branch" >&2
            return 1
        fi
        local worktree_path
        if ! IFS= read -r -d '' worktree_path < <(_wt_paths "$branch_name"); then
            echo "No worktree found for branch: $branch_name" >&2
            return 1
        fi
        if [[ "$worktree_path" == "$(git rev-parse --show-toplevel)" ]]; then
            echo "Cannot delete the current worktree" >&2
            return 1
        fi
        git worktree remove "${remove_options[@]}" -- "$worktree_path" || return $?
        git branch "$branch_option" -- "$branch_name" || return $?
        echo "Removed worktree and branch: $branch_name"

    elif [[ "$cmd" == "init" ]]; then
        # Check if .wt_hook.sh already exists
        if [[ -f ".wt_hook.sh" ]]; then
            echo ".wt_hook.sh already exists"
            return 1
        fi

        # Create .wt_hook.sh with copy and symlink template
        cat > .wt_hook.sh << 'EOF'
#!/bin/bash
set -e -o pipefail
# .wt_hook.sh - Run with Bash in the new worktree by wt add/co and Claude Code
# Available variables:
# - $WT_WORKTREE_PATH: Path to the new worktree (current directory)
# - $WT_BRANCH_NAME: Name of the branch
# - $WT_PROJECT_ROOT: Path to the original project root

# Files and directories to COPY from project root to worktree
# Use this when each worktree needs independent copies
copy_items=()

# Files and directories to SYMLINK from project root to worktree
# Use this when worktrees should share the same files (e.g., .env, .claude)
link_items=()

# Copy items
for item in "${copy_items[@]}"; do
    if [[ -f "$WT_PROJECT_ROOT/$item" ]]; then
        cp "$WT_PROJECT_ROOT/$item" "$item"
        echo "Copied file $item to worktree"
    elif [[ -d "$WT_PROJECT_ROOT/$item" ]]; then
        rsync -a "$WT_PROJECT_ROOT/$item/" "$item/"
        echo "Copied directory $item to worktree"
    fi
done

# Symlink items (absolute paths to avoid breakage with nested paths)
for item in "${link_items[@]}"; do
    if [[ -e "$WT_PROJECT_ROOT/$item" ]]; then
        if [[ -e "$item" || -L "$item" ]]; then
            echo "Skipped $item (already exists)"
        else
            ln -s "$WT_PROJECT_ROOT/$item" "$item"
            echo "Linked $item -> $WT_PROJECT_ROOT/$item"
        fi
    fi
done

# Example: Install dependencies
# npm install

# Add your custom initialization commands here
EOF

        chmod +x .wt_hook.sh
        echo "Created .wt_hook.sh template"

    elif [[ "$cmd" == "clean" ]]; then
        local current_branch base=main merged_branches branch worktree_path confirmation
        current_branch=$(git branch --show-current) || return $?
        git show-ref --verify --quiet refs/heads/main || base=master
        merged_branches=$(git branch --merged "$base" --format='%(refname:short)') || return $?
        local -a branches_to_delete=()
        while IFS= read -r branch; do
            [[ -z "$branch" || "$branch" == main || "$branch" == master || "$branch" == "$current_branch" ]] && continue
            branches_to_delete+=("$branch")
        done <<< "$merged_branches"
        if (( ${#branches_to_delete} == 0 )); then
            echo "No merged branches to clean up"
            return 0
        fi
        echo 'The following merged branches will be deleted:'
        printf '  %s\n' "${branches_to_delete[@]}"
        echo -n "Delete these branches and worktrees? (y/n): "
        read -r confirmation
        if [[ "$confirmation" != y && "$confirmation" != Y ]]; then
            echo "Cancelled"
            return 0
        fi
        local deleted_count=0 result=0
        for branch in "${branches_to_delete[@]}"; do
            if IFS= read -r -d '' worktree_path < <(_wt_paths "$branch"); then
                wt remove "$branch" || { result=1; continue; }
            else
                git branch -d -- "$branch" || { result=1; continue; }
            fi
            (( deleted_count++ ))
        done
        echo "Cleaned up $deleted_count branch(es)"
        return $result

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
            if git remote | grep -Fxq -- "$potential_remote"; then
                remote_name="$potential_remote"
                branch_name="${match[2]}"
            fi
        fi

        # Check if branch is already checked out in a worktree
        local existing_worktree
        if IFS= read -r -d '' existing_worktree < <(_wt_paths "$branch_name"); then
            echo "Error: Branch '$branch_name' is already checked out at: $existing_worktree"
            return 1
        fi

        local project_name=$(basename "$project_root")
        local parent_dir=$(dirname "$project_root")
        local safe_name=${branch_name//\//-}
        local worktree_path="$parent_dir/${project_name}-${safe_name}"

        # Check if local branch exists
        if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            echo "Creating worktree from local branch: $branch_name"
            git worktree add "$worktree_path" "$branch_name" || return $?
        else
            # Local branch doesn't exist, try remote
            echo "Local branch not found, checking remote..."

            # Use specified remote or default to origin
            local target_remote="${remote_name:-origin}"

            # Fetch from remote
            echo "Fetching from $target_remote..."
            git fetch "$target_remote" || return $?

            # Check if remote branch exists
            if git show-ref --verify --quiet "refs/remotes/$target_remote/$branch_name"; then
                echo "Creating worktree from remote branch: $target_remote/$branch_name"
                git worktree add -b "$branch_name" "$worktree_path" --track "$target_remote/$branch_name" || return $?
            else
                echo "Error: Branch '$branch_name' not found in local or remote '$target_remote'"
                return 1
            fi
        fi

        cd -- "$worktree_path" || return $?
        _wt_setup "$project_root" "$worktree_path" "$branch_name"

    else
        echo "Unknown command: $cmd"
        echo "Usage:"
        echo "  wt                 - Show worktree list with fzf (Ctrl+D to delete)"
        echo "  wt add <branch>    - Create new branch and worktree"
        echo "  wt co <branch>     - Checkout existing branch to worktree"
        echo "  wt remove [-D] <branch> - Remove worktree and branch (-D: force)"
        echo "  wt clean           - Remove merged branches and their worktrees"
        echo "  wt init            - Create .wt_hook.sh template"
        return 1
    fi
}
