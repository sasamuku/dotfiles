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

5. Write the **Key Changes** section — a narrative walkthrough that tells the story of the PR's changes file by file. The reviewer should understand the full picture before opening the diff:

   - Analyze the diff and determine the optimal reading order. Typically: data structures / domain models first, then core logic, then integration / orchestration, then UI / presentation, then tests / stories last.
   - For each file, write a **`#### N.` heading block** (e.g. `#### 1.`, `#### 2.`). Do NOT use markdown numbered lists (`1.` at line start) — use `####` headings to avoid nested-numbering conflicts:
     - The heading line: `#### N.` followed by the file path in bold backticks, tagged with `(new)`, `(modified)`, `(deleted)`, or `(renamed)` as appropriate
     - Lines 2+: Write as if explaining to someone who just joined the project. Cover:
       - What this file is responsible for in the codebase (architectural context)
       - What specifically was changed or added in this PR and why
       - How it connects to the previous and next files in the reading order
       - Any non-obvious design decisions or trade-offs worth noting
     - Quote key code snippets with inline comments to make the explanation concrete. Show the most important type, function signature, or logic block so the reviewer knows what to look for in the diff. Wrap code blocks in a `>` blockquote so they render cleanly in Claude Code output.
   - If project-specific terms, abbreviations, or domain jargon appear, add a short inline explanation on first use.
   - The reader should be able to review the diff confidently after reading this section alone, without needing to ask the author for context.

6. Write the **Findings** section. For each issue found by the code-reviewer agent:
   - Classify by priority:
     - 🔴 **Critical** - Security vulnerabilities, bugs, data loss risks
     - 🟡 **Warning** - Code quality concerns, potential issues
     - 🟢 **Suggestion** - Improvements, style, readability
   - Specify the file and line number (e.g., `src/auth.ts:42`)
   - Describe the issue concisely
   - Provide a concrete recommendation for how to fix it

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

#### 1. **`src/errors.ts`** (new)

Start here. This project uses custom error classes to distinguish between different failure modes in the authentication flow. This PR introduces `TokenExpiredError`, thrown when a user attempts a password reset with an expired token. By giving it a dedicated class, downstream code (middleware in #3) can catch it specifically and return the correct HTTP status.

> ```ts
> // src/errors.ts:1-6
> // A dedicated error class so middleware can distinguish "expired token"
> // from other auth failures and return 401 instead of a generic 500.
> export class TokenExpiredError extends Error {
>   constructor(message = "Reset token has expired") {
>     super(message);
>   }
> }
> ```

Both auth.ts (#2) and middleware.ts (#3) import this type, so reading it first gives you the vocabulary for the rest of the PR.

#### 2. **`src/auth.ts`** (modified)

The core authentication module handling login, logout, and password reset. The bug being fixed is that `resetPassword()` previously accepted any structurally valid token without checking its expiry, so expired links silently succeeded. This PR adds `validateToken()` at the top of the reset flow:

> ```ts
> // src/auth.ts:12-18
> // Called before any password update — rejects stale tokens early
> // so no side effects (DB writes, emails) happen on invalid requests.
> function validateToken(token: string) {
>   if (isExpired(token)) {
>     throw new TokenExpiredError("Reset token has expired");
>   }
> }
> ```

This function throws the `TokenExpiredError` defined in #1. The next file (#3) handles what happens when this error reaches the HTTP layer.

#### 3. **`src/middleware.ts`** (modified)

The centralized error-handling layer that translates domain exceptions into HTTP responses. This PR adds a catch clause for `TokenExpiredError` from #1:

> ```ts
> // src/middleware.ts:25-28
> // Without this clause, the TokenExpiredError from auth.ts
> // would bubble up as an unhandled 500.
> if (error instanceof TokenExpiredError) {
>   return res.status(401).json({ message: error.message });
> }
> ```

This ensures the client receives a meaningful 401 rejection instead of a confusing server error.

---

### Findings

| # | Priority | File | Issue | Recommendation |
|---|----------|------|-------|----------------|
| 1 | 🔴 Critical | src/auth.ts:42 | SQL injection via unsanitized input | Use parameterized queries |
| 2 | 🟡 Warning | src/api.ts:15 | Missing error handling in async call | Add try-catch with proper error propagation |
| 3 | 🟢 Suggestion | src/utils.ts:8 | Duplicated logic | Extract into shared helper |
...
````
