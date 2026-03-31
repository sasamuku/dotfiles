---
name: babysit
description: Autonomously triage PR review comments, apply necessary fixes, commit, push, and reply to comments. Designed for use with /loop 5m /babysit to continuously babysit PRs.
disable-model-invocation: true
allowed-tools: Bash(git *), Bash(gh *)
---

# Babysit PR

Autonomous PR maintenance loop. Triages review comments, applies fixes where needed, and replies to addressed comments.

## Workflow

### Step 1: Detect current PR

```bash
gh pr view --json number,headRepository,state -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name, state: .state}'
```

If no open PR on the current branch, exit silently.
If the PR state is `MERGED` or `CLOSED`, print `✅ PR is merged/closed. Stopping.` and exit.

### Step 2: Triage review comments

Run @.claude/skills/triage-pr-comments/SKILL.md (Phase 1) to fetch and categorize all unresolved comments.

### Step 3: Autonomous decision-making

For each comment, decide autonomously:

| Priority | Action |
|----------|--------|
| 🔴 Must | Fix it. |
| 🟡 Investigate | Fix if clearly correct and low-risk. Skip if ambiguous or risky. |
| 🟢 Info | Skip unless trivially safe (e.g., unused import removal). |

**Do not fix** if:
- The change requires product/design decisions
- The fix could break other behavior
- The comment is already resolved (has a reply)

### Step 4: Commit and push (if any fixes were applied)

Run @.claude/skills/commit/SKILL.md with `-y` option (skip approval), then @.claude/skills/push/SKILL.md.

### Step 5: Reply to addressed comments

Run @.claude/skills/triage-pr-comments/SKILL.md (Phase 2) for comments that were fixed or investigated.

### Step 6: Report

```
✅ Fixed #1, #3 — committed and pushed (abc1234)
⏭️  Skipped #2 (ambiguous), #4 (already resolved)
```

If nothing to do: `✅ No actionable comments found.`
