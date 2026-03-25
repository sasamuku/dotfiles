#!/bin/bash
set -euo pipefail
# WorktreeCreate hook - git worktree 作成 + .wt_hook.sh 実行
# stdout: worktree の絶対パス（Claude Code が使用）
# stderr: ログ出力

INPUT=$(cat)

NAME=$(echo "$INPUT" | jq -r '.name // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$NAME" ] || [ -z "$CWD" ]; then
    echo "Missing required fields: name and cwd" >&2
    exit 1
fi

if ! git check-ref-format --allow-onelevel "$NAME" 2>/dev/null; then
    echo "Invalid branch name: $NAME" >&2
    exit 1
fi

PROJECT_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || {
    echo "Not in a git repository" >&2
    exit 1
}

PROJECT_NAME=$(basename "$PROJECT_ROOT")
PARENT_DIR=$(dirname "$PROJECT_ROOT")
SAFE_NAME=$(echo "$NAME" | tr '/' '-')
WORKTREE_PATH="$PARENT_DIR/${PROJECT_NAME}-${SAFE_NAME}"

if ! git -C "$PROJECT_ROOT" worktree add -b "$NAME" "$WORKTREE_PATH" >/dev/null 2>&1; then
    echo "Failed to create worktree" >&2
    exit 1
fi

# Execute .wt_hook.sh if it exists
if [ -f "$PROJECT_ROOT/.wt_hook.sh" ]; then
    echo "Executing .wt_hook.sh..." >&2
    export WT_WORKTREE_PATH="$WORKTREE_PATH"
    export WT_BRANCH_NAME="$NAME"
    export WT_PROJECT_ROOT="$PROJECT_ROOT"
    if ! (cd "$WORKTREE_PATH" && bash "$PROJECT_ROOT/.wt_hook.sh") >&2; then
        echo "Warning: .wt_hook.sh failed (worktree was created)" >&2
    fi
fi

# stdout にパスを出力（Claude Code が worktree パスとして使用）
echo "$WORKTREE_PATH"
