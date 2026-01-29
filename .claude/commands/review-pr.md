---
description: Comprehensive PR review with code analysis and feedback
---

## Task

Perform a thorough code review of a GitHub Pull Request.

### Steps

1. Extract PR number from the argument (supports PR URL like `https://github.com/owner/repo/pull/123` or just number like `123`)

2. Fetch PR information:
   ```bash
   gh pr view <number>
   ```

3. Get the diff:
   ```bash
   gh pr diff <number>
   ```

4. Fetch existing review comments:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   gh api repos/{owner}/{repo}/pulls/{number}/reviews
   ```

5. Use **code-reviewer** agent to perform the review with:
   - PR title and description
   - All changed files (diff)
   - Existing review comments for context

### Arguments

Required: PR number or PR URL (e.g., `123` or `https://github.com/owner/repo/pull/123`)

$ARGUMENTS

### Output

The code-reviewer agent will provide structured feedback organized by priority (Critical, Warning, Suggestion) with specific file locations and fix recommendations.
