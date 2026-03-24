---
name: review-pr
description: Comprehensive PR review with code analysis and feedback
disable-model-invocation: true
---

# Review PR

Perform a thorough code review of a GitHub Pull Request.

## Arguments

$ARGUMENTS

- **First argument** (required): PR number or PR URL (e.g., `123` or `https://github.com/owner/repo/pull/123`)

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

5. Write the **Reading Guide** section — a numbered list showing which files to read and in what order, so the reviewer has a mental map before diving into the diff:

   - Analyze the diff and determine the optimal reading order. Start from the file that establishes the core intent of the PR (e.g., domain model, API contract, schema change), then proceed to files that build on or depend on it.
   - For each file, write one line: the file path and its **role** — how it contributes to achieving the PR's stated purpose.
   - Mark new files with `(new)`.

6. Write the **Key Changes** section:

   Group all changes into logical semantic units. Each group represents a cohesive purpose spanning one or more files. Order groups so the reviewer can understand the PR from top to bottom.

   Each group has:
   - A short descriptive title
   - List of relevant files
   - **Context**: briefly explain where in the architecture these files sit and their role (1 sentence)
   - Explain **what** the change does and **why** it exists
   - Quote key code snippets to illustrate the change
   - If project-specific terms, abbreviations, or domain jargon appear, add a short inline explanation on first use

7. Classify each finding by priority:
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

### Reading Guide

1. `src/auth.ts` — Core change: adds token expiry validation logic
2. `src/middleware.ts` — Integrates the new validation into the request pipeline
3. `src/errors.ts` (new) — Defines `TokenExpiredError` used by the validation

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
