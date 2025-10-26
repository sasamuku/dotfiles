---
description: Commit changes and push to remote repository
---

## Task
Commit current branch changes and push to remote repository:

1. Check changes with `git status`
2. Stage changed files with `git add`
3. Create commit message and commit
   - Auto-generate commit message from changes
   - Append the following footer:
     ```
     🤖 Generated with [Claude Code](https://claude.com/claude-code)

     Co-Authored-By: Claude <noreply@anthropic.com>
     ```
4. Push to remote with `git push` (use `-u` flag if upstream not set)
5. Display completion message

Follow the "Committing changes with git" section in CLAUDE.md for commit processing.
