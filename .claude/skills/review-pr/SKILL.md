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

1. Fetch PR info and diff:
   ```bash
   gh pr view <number>
   gh pr diff <number>
   ```

2. Fetch existing review comments for context:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   gh api repos/{owner}/{repo}/pulls/{number}/reviews
   ```

3. Use **code-reviewer** agent to perform the review with the PR title, description, diff, and existing comments.

4. Write the **Overview** section. The goal is for the reviewer to understand the PR in 5 seconds:
   - Summary: one plain-language sentence — include the business/product **background** so even someone on day 1 of the project understands why this PR exists
   - Type, Scope, Impact, Size — fill in the table so the reviewer can gauge effort and risk at a glance

5. Group all changes into logical semantic units for the **Key Changes** section. Each group represents a cohesive purpose spanning one or more files. Order groups so the reviewer can understand the PR from top to bottom. Write as if the reader has never seen this codebase. For each group:
   - Give it a short descriptive title
   - **Context**: briefly explain where in the architecture these files sit and their role (1 sentence)
   - Explain **what** the change does and **why** it exists
   - List the relevant files
   - Quote key code snippets to illustrate the change
   - If project-specific terms, abbreviations, or domain jargon appear, add a short inline explanation on first use

6. Classify each finding by priority:
   - 🔴 **Critical** - Security vulnerabilities, bugs, data loss risks
   - 🟡 **Warning** - Code quality concerns, potential issues
   - 🟢 **Suggestion** - Improvements, style, readability

## Output Format

````
## PR Review Summary

### Overview

> Users were unable to reset their password because the reset token was not validated before use, allowing expired tokens to succeed.

| | |
|---|---|
| **Type** | Bug fix |
| **Scope** | Authentication — password reset flow |
| **Impact** | Expired reset links will now correctly show an error instead of silently succeeding |
| **Size** | 3 files changed, +45 / -12 lines |

### Key Changes

#### 1. Add token expiry validation
**Context**: `src/auth.ts` is the core authentication module that handles all token operations.
**Purpose**: Reject expired password-reset tokens before processing the reset.
**Files**: `src/auth.ts`, `src/middleware.ts`

> ```ts
> // src/auth.ts:12-18
> function validateToken(token: string) {
>   if (isExpired(token)) {
>     throw new TokenExpiredError("Reset token has expired")
>   }
> }
> ```
This new validation runs before the password is updated. Previously, `resetPassword()` accepted any structurally valid token regardless of expiry.

#### 2. <Title>
...

---

### Findings

| # | Priority | File | Issue | Recommendation |
|---|----------|------|-------|----------------|
| 1 | 🔴 Critical | src/auth.ts:42 | SQL injection via unsanitized input | Use parameterized queries |
| 2 | 🟡 Warning | src/api.ts:15 | Missing error handling in async call | Add try-catch with proper error propagation |
| 3 | 🟢 Suggestion | src/utils.ts:8 | Duplicated logic | Extract into shared helper |
...
````
