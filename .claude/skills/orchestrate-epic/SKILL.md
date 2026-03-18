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
2. **Launch member**: Use the Agent tool with:
   - `name: "member-<issue-number>"`
   - `isolation: "worktree"`
   - `mode: "auto"`
   - `run_in_background: true`
   - Prompt:
     ```
     You are a MEMBER of an Epic orchestration team.
     Your assignment: Sub-issue #<number> in <owner>/<repo>.
     Title: <title>
     URL: <url>

     Details:
     <body>

     Instructions — follow the /feature-dev workflow:

     Phase A: Understand
     1. Use /feature-dev to deeply explore the codebase architecture
        related to this sub-issue
     2. Identify existing patterns, conventions, and dependencies
     3. If anything is unclear or ambiguous about the requirements,
        ASK the user before proceeding — do NOT guess.
        Questions will be relayed through the leader.

     Phase B: Implement
     4. Only after understanding is sufficient, implement the changes
     5. Follow existing code patterns and conventions
     6. Run tests and linting if configured

     Phase C: Report
     7. STOP and report what you implemented:
        - Files changed and summary of changes
        - Test results
        - Any concerns or open questions
     8. WAIT for user review. Do NOT commit or create PR yet.

     Phase D: Deliver (only after user approval)
     9. Use /commit -y to commit changes
     10. Push and use /create-pr to create a PR that closes #<number>
     11. Report PR URL
     ```
3. **Inform user**:
   ```
   member-<N> is working on #<N>: <title> in the background.
   - Check progress: ask me and I'll query the member
   - Give instructions: tell me what to relay
   - Skip: say "skip" to move on
   ```
4. **On implementation complete**: Member reports changes. Leader relays to user for review.
5. **User review**: User reviews the changes, requests fixes if needed.
   - If fixes needed: Leader relays to member via SendMessage. Member fixes and reports again.
   - If approved: Leader tells member to proceed to Phase D (commit & PR).
6. **On PR created**: Report PR URL and ask user before starting the next sub-issue.

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
