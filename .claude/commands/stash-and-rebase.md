---
description: Stash changes, rebase onto latest main, and reapply stash
---

## Task

Execute the following git operations in sequence:

1. Stash all current changes including untracked files: `git stash push -u -m "Auto-stash before rebase"`
2. Fetch the latest changes from remote: `git fetch origin`
3. Rebase the current branch onto the latest main: `git rebase origin/main`
4. Reapply the stashed changes: `git stash pop`

If the rebase encounters conflicts, pause and inform the user so they can resolve them before attempting to pop the stash.
