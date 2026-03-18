---
name: orchestrate-epic
description: Orchestrate Epic issue as leader. Delegate sub-issues to named member agents in isolated worktrees. Monitor progress, review results, and steer members via SendMessage.
disable-model-invocation: true
argument-hint: <epic-issue-url>
---

# Orchestrate Epic

Act as leader. Delegate sub-issues to named member agents in isolated worktrees.

## Arguments

GitHub Epic issue URL (e.g., `https://github.com/owner/repo/issues/123`)

$ARGUMENTS

## Roles

### Leader (= this main session)
- Reads the Epic and identifies sub-issues
- Prioritizes and orders sub-issues considering dependencies
- Launches member agents one by one
- Reviews each member's output before moving to the next
- Tracks overall progress and reports to the user
- Relays user instructions to members via SendMessage
- Does NOT write code

### Member (`member-<issue-number>`)
- Follows the `/feature-dev` workflow: understand codebase deeply before writing code
- If anything is unclear or ambiguous, asks the user (via leader) before proceeding
- Implements the changes only after understanding is sufficient
- Runs tests/lint if available
- Reports implementation to the user for review (does NOT commit yet)
- After user approval, commits via `/commit -y` and creates PR via `/create-pr`
- Does NOT decide what to work on — the leader decides

## Workflow

### Phase 1: Read Epic and Identify Sub-issues

1. Extract owner, repo, and issue number from the URL
2. Fetch Epic details:
   ```bash
   gh issue view <number> --repo <owner>/<repo> --json number,title,body,state,url
   ```
3. Fetch sub-issues:
   ```bash
   gh api repos/<owner>/<repo>/issues/<number>/sub_issues --paginate --jq '.[] | {number, title, state}'
   ```
4. If the API fails, fall back to parsing the Epic body for issue references (`#123`, `- [ ] #123`)
5. For each sub-issue, fetch its details:
   ```bash
   gh issue view <sub-number> --repo <owner>/<repo> --json number,title,body,state,url
   ```
6. Filter to **open** sub-issues only
7. Analyze dependencies and determine execution order
8. Print the ordered sub-issue list and ask the user to confirm before proceeding

### Phase 2: Sequential Delegation

For each open sub-issue (in order):

1. **Announce**: Print `Starting member-<issue-number> on #<number>: <title>`
2. **Launch member**: Use the Agent tool with `subagent_type: "epic-member"`. CRITICAL: you MUST set `isolation: "worktree"`.
   ```
   Agent({
     name: "member-<issue-number>",
     subagent_type: "epic-member",
     isolation: "worktree",
     prompt: "Your assignment: Sub-issue #<number> in <owner>/<repo>.\nTitle: <title>\nURL: <url>\n\nDetails:\n<body>"
   })
   ```
   The agent definition at `@.claude/agents/epic-member.md` handles the workflow (understand → implement → report → deliver).
3. **Member runs in foreground**: User can see progress in real time.
4. **On Phase C (Report)**: Member reports changes. User reviews directly.
   - If fixes needed: User gives feedback, leader relays via SendMessage. Member fixes and reports again.
   - If approved: Leader tells member to proceed to Phase D (commit & PR).
5. **On PR created**: Report PR URL and ask user before starting the next sub-issue.

### Interacting with Members

The user can ask at any time to:
- **Check status**: Leader uses `SendMessage(to: "member-<N>")` to ask for progress
- **Give direction**: Leader uses `SendMessage(to: "member-<N>")` to relay instructions
- **Skip**: Move to the next sub-issue without waiting

### Phase 3: Summary

After all sub-issues are processed, print:

```
## Epic Orchestration Summary

Epic: <url>

| Sub-issue | Title | Member | Status | Branch/PR |
|-----------|-------|--------|--------|-----------|
| #456      | ...   | member-456 | Done | PR #789 |
| #457      | ...   | member-457 | Done | PR #790 |
| #458      | ...   | member-458 | Failed | (error) |

Completed: <n>/<total>
```
