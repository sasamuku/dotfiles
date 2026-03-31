---
name: babysit
description: Autonomously triage PR review comments, apply necessary fixes, commit, push, and reply to comments. Designed for use with /loop 5m /babysit to continuously babysit PRs.
disable-model-invocation: true
allowed-tools: Bash(git *), Bash(gh *), Read, Edit, Write
---

# Babysit PR

Autonomous PR maintenance loop. Triages review comments, applies fixes where needed, and replies to addressed comments. No user interaction — fully autonomous.

## Workflow

### Step 1: Detect current PR

```bash
gh pr view --json number,headRepository,state -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name, state: .state}'
```

- If no open PR on the current branch, exit silently.
- If state is `MERGED` or `CLOSED`, print `✅ PR is merged/closed. Stopping.` and exit.

### Step 2: Fetch unresolved review comments

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

Filter to only unresolved comments (no existing reply in the thread).

### Step 3: Categorize each comment

For each comment, assign a priority:

- 🔴 **Must** — bugs, security issues, breaking changes
- 🟡 **Investigate** — may or may not require changes
- 🟢 **Info** — style suggestions, nitpicks

### Step 4: Autonomous decision-making

For each comment, decide and act without user input:

| Priority | Action |
|----------|--------|
| 🔴 Must | Fix it. Read the file, apply the change. |
| 🟡 Investigate | Fix if clearly correct and low-risk. Skip if ambiguous or risky. |
| 🟢 Info | Skip unless trivially safe (e.g., removing an unused import). |

**Do not fix** if:
- The change requires product or design decisions
- The fix could break other behavior
- Intent of the comment is unclear

### Step 5: Commit and push (only if fixes were applied)

Run @.claude/skills/commit/SKILL.md with `-y` option, then @.claude/skills/push/SKILL.md.

### Step 6: Reply to each comment

For every comment processed, post a reply autonomously:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -X POST -f body="{reply}"
```

Reply templates:

| Situation | Reply |
|-----------|-------|
| Fixed | `Fixed in {commit_hash}.` |
| Won't fix — ambiguous | `Skipping for now — intent is unclear. Please clarify if action is needed.` |
| Won't fix — risky | `Keeping current approach to avoid unintended side effects.` |
| Investigated, no change needed | `Investigated — current implementation handles this correctly.` |
| Info, skipped | `Noted.` |

### Step 7: Report

```
✅ Fixed #1, #3 — committed and pushed (abc1234)
⏭️  Skipped #2 (ambiguous), #4 (risky)
💬 Replied to #1, #2, #3, #4
```

If nothing to do: `✅ No actionable comments found.`
