---
name: orchestrate-epic
description: Orchestrate Epic issue as team leader. Delegate sub-issues to member agents in isolated worktrees. Members run in background and communicate via SendMessage.
disable-model-invocation: true
argument-hint: <epic-issue-url>
---

# Orchestrate Epic

Act as team leader. Delegate sub-issues to member agents running in isolated worktrees.

> **NOTE**: Do NOT use Agent Teams (`team_name` / `TeamCreate`). Agent Teams + worktree isolation is a known incompatibility (anthropics/claude-code#33045). Instead, launch members as background agents with `isolation: "worktree"` and communicate via SendMessage by agent name.

## Arguments

GitHub Epic issue URL (e.g., `https://github.com/owner/repo/issues/123`)

$ARGUMENTS

## Roles

### Leader (= this main session)
- Reads the Epic and identifies sub-issues
- Prioritizes and orders sub-issues considering dependencies
- Asks user to choose execution mode (sequential or parallel)
- Launches member agents in isolated worktrees
- Reviews each member's report and approves deliveries
- Relays user instructions to members via SendMessage
- Does NOT write code
- Does NOT create branches — stays on the base branch (the branch active at invocation)

### Member (`member-<issue-number>`)
- Defined in `@.claude/agents/epic-member.md`
- Runs in background with `isolation: "worktree"`
- Works exclusively within the worktree
- Follows understand → implement → report → deliver workflow
- Communicates progress via SendMessage

## Workflow

### Phase 1: Read Epic and Plan

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
8. Print the ordered sub-issue list and ask the user:

> **Execution mode:**
> - **Sequential** — members launched one by one, each waits for approval before the next starts (for dependent work)
> - **Parallel** — all members launched simultaneously, work independently (for independent work)
>
> Which mode? And confirm the sub-issue order?

### Phase 2: Delegation

**Member launch pattern:**
```
Agent({
  name: "member-<issue-number>",
  subagent_type: "epic-member",
  isolation: "worktree",
  run_in_background: true,
  prompt: "Your assignment: Sub-issue #<number> in <owner>/<repo>.\nTitle: <title>\nURL: <url>\n\nDetails:\n<body>\n\nSend your report to: team-lead\n\nREMINDER: You are in an isolated worktree. NEVER checkout/switch branches in the main repo. Stay in your worktree directory. Run `pwd` before any git operation to confirm."
})
```

#### Sequential Mode

For each sub-issue in order:
1. **Announce**: Print `Starting member-<issue-number> on #<number>: <title>`
2. **Launch member** with `run_in_background: true`.
3. **On report**: Member sends report via SendMessage. Leader reviews.
   - If fixes needed: relay feedback via `SendMessage(to: "member-<issue-number>")`. Member fixes and reports again.
   - If approved: tell member to proceed to deliver (commit & PR).
   - If member fails or stops responding: mark sub-issue as failed and ask user whether to continue.
4. **On PR created**: Report PR URL. Wait for user approval before launching the next member.
5. **Shutdown member**: Send `SendMessage(to: "member-<issue-number>", message: {type: "shutdown_request"})`.

#### Parallel Mode

1. **Launch all members** with `run_in_background: true`.
2. **Monitor**: Members send reports via SendMessage as they complete. Messages are delivered automatically.
3. **Review each report** as it arrives:
   - If fixes needed: relay feedback via SendMessage.
   - If approved: tell member to proceed to deliver.
4. Continue until all members have delivered or failed.

### Interacting with Members

The user can ask at any time to:
- **Check status**: Leader uses `SendMessage(to: "member-<N>")` to ask for progress
- **Give direction**: Leader uses `SendMessage(to: "member-<N>")` to relay instructions
- **Skip**: Move to the next sub-issue without waiting

### Phase 3: Summary and Cleanup

After all sub-issues are processed, print:

```
## Epic Orchestration Summary

Epic: <url>
Mode: Sequential | Parallel

| Sub-issue | Title | Member | Status | Branch/PR |
|-----------|-------|--------|--------|-----------|
| #456      | ...   | member-456 | Done | PR #789 |
| #457      | ...   | member-457 | Done | PR #790 |
| #458      | ...   | member-458 | Failed | (error) |

Completed: <n>/<total>
```

Then shut down remaining members via `SendMessage` with `message: {type: "shutdown_request"}`.
