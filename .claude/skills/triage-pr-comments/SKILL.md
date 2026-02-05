---
name: triage-pr-comments
description: Triage PR review comments with priority categorization (must/investigate/info). Use when handling AI reviewer feedback (CodeRabbit, Copilot, etc.) or managing PR comments systematically.
disable-model-invocation: true
allowed-tools: Bash(gh *)
---

# PR Review Comments Manager

Two-phase workflow for managing PR review comments from AI reviewers (CodeRabbit, Copilot, etc.) and human reviewers.

## Arguments

PR number or URL (optional - uses current branch PR if omitted)

$ARGUMENTS

---

## Phase 1: Analyze & Categorize

### Step 1: Get PR information

```bash
gh pr view --json number,headRepository -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name}'
```

### Step 2: Fetch all review comments

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

### Step 3: Categorize and present

For each comment, assign:
- **ID**: Sequential number (e.g., #1, #2, #3)
- **Priority**:
  - 🔴 **Must** - Bugs, security issues, breaking changes - requires fix
  - 🟡 **Investigate** - Needs consideration, may or may not require changes
  - 🟢 **Info** - Informational, style suggestions, minor nitpicks

### Output Format

Present to user as a table:

```
## PR Review Comments Summary

| ID | Priority | File | Summary |
|----|----------|------|---------|
| #1 | 🔴 Must | src/auth.ts:42 | Null check missing before accessing user.id |
| #2 | 🟡 Investigate | src/api.ts:15 | Consider using async/await instead of .then() |
| #3 | 🟢 Info | src/utils.ts:8 | Unused import statement |
...

### Details

**#1** 🔴 Must - src/auth.ts:42
> Original comment text here...
Intent: Prevent potential runtime error when user object is undefined

**#2** 🟡 Investigate - src/api.ts:15
> Original comment text here...
Intent: Code style suggestion for better readability

...
```

After presenting, wait for user to address the issues.

---

## Phase 2: Reply to Addressed Comments

When user says "reply to comments" or similar:

### Step 1: Identify addressed comments

Ask user which comment IDs were addressed, or detect from recent commits/changes in context.

### Step 2: Reply only to addressed comments

For each addressed comment, post a threaded reply:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST \
  -f body="Reply content" \
  -F in_reply_to={comment_id}
```

### Reply Guidelines

- **Only reply to comments that were actually addressed**
- Reference commit hash when a fix was made (e.g., "Fixed in abc123")
- For "won't fix" decisions, explain reasoning
- Skip comments still pending investigation
- Keep replies concise

### Example Replies

| Situation | Reply |
|-----------|-------|
| Fixed | "Fixed in abc123. Added null check as suggested." |
| Won't fix | "Keeping current approach because X." |
| Investigated, no change needed | "Investigated - current implementation handles this case via Y." |
