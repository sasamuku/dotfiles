---
description: Review all changes (commits and working changes) and organize into appropriate commit granularity
---

## Task

Execute the following workflow to organize all changes into well-structured commits:

1. Review the current state:
   - Run `git status` to see unstaged and staged changes
   - Run `git diff` to see unstaged changes
   - Run `git diff --staged` to see staged changes
   - Run `git log origin/main..HEAD --oneline` to list existing commits
   - Run `git log origin/main..HEAD` for detailed commit messages

2. Analyze all changes and determine optimal commit structure:
   - Group related changes across commits and working directory
   - Identify logical units that should be separate commits
   - Consider proper commit granularity (one logical change per commit)
   - Determine which changes should be combined or split
   - Decide on clear, descriptive commit messages for each logical unit

3. Execute the reorganization automatically:
   - If there are working changes, create temporary commits or stash them
   - Use interactive rebase to reorganize existing commits
   - Apply working changes to appropriate commits using `git commit --amend` or as new commits
   - Ensure the final commit history is clean and logical
   - Show the final result after completion

Note: This command automatically restructures commits based on optimal commit granularity without requiring user approval.
