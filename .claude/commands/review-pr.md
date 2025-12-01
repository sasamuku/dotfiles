---
description: Comprehensive PR review with code analysis and feedback
---

## Task

Perform a thorough code review of the GitHub Pull Request. Assumes the current branch matches the PR branch.

### Steps
1. Extract PR number from the argument (supports PR URL like `https://github.com/owner/repo/pull/123` or just number like `123`)
2. Use `gh pr view <number>` to fetch PR information (title, description, author, status)
3. Use `gh pr diff <number>` to get the list of changed files
4. Use `gh api` to fetch existing review comments:
   - `gh api repos/{owner}/{repo}/pulls/{number}/comments` for line comments
   - `gh api repos/{owner}/{repo}/pulls/{number}/reviews` for review summaries
5. Analyze the changes:
   - Read modified files and understand the changes
   - Check for code quality, patterns, and potential issues
   - Look for missing tests or documentation
   - Identify security concerns or performance issues
6. Provide structured feedback with:
   - Summary of changes
   - Positive aspects
   - Areas for improvement
   - Specific recommendations

### Arguments
Required: PR number or PR URL (e.g., `123` or `https://github.com/owner/repo/pull/123`)

$ARGUMENTS
