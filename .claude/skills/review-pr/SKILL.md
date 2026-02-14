---
name: review-pr
description: Comprehensive PR review with code analysis and feedback
disable-model-invocation: true
---

# Review PR

Perform a thorough code review of a GitHub Pull Request.

## Arguments

PR number or PR URL (e.g., `123` or `https://github.com/owner/repo/pull/123`)

$ARGUMENTS

## Steps

1. Extract PR number from argument

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

## Output

For each finding, assign:
- **ID**: Sequential number (e.g., #1, #2, #3)
- **Priority**:
  - 🔴 **Critical** - Security vulnerabilities, bugs, data loss risks - must fix
  - 🟡 **Warning** - Code quality concerns, potential issues - should fix
  - 🟢 **Suggestion** - Improvements, style, readability - nice to have

### Output Format

Present to user as a table:

```
## PR Review Summary

### Overview
- **Purpose**: One-sentence summary of what this PR aims to achieve
- **Approach**: Brief description of how the changes accomplish the purpose

### Findings

| ID | Priority | File | Summary |
|----|----------|------|---------|
| #1 | 🔴 Critical | src/auth.ts:42 | SQL injection via unsanitized user input |
| #2 | 🟡 Warning | src/api.ts:15 | Missing error handling in async call |
| #3 | 🟢 Suggestion | src/utils.ts:8 | Extract duplicated logic into helper |
...

### Details

**#1** 🔴 Critical - src/auth.ts:42
> Description of the issue
Recommendation: How to fix it

**#2** 🟡 Warning - src/api.ts:15
> Description of the issue
Recommendation: How to fix it

...
```
