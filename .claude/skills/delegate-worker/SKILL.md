---
name: delegate-worker
description: Delegate a task to a worktree-worker agent running in an isolated git worktree. Use this skill when you want a sub-agent to implement code changes, fix bugs, or investigate errors in a separate worktree — keeping the main session clean. Trigger on phrases like "delegate this to a worker", "fix this in a worktree", "have a worker handle this", or when the user wants code changes done in isolation.
argument-hint: <task-description>
---

# Delegate Worker

Launch a `worktree-worker` agent in an isolated git worktree to handle a task in the background.

## Arguments

$ARGUMENTS

## Workflow

### 1. Prepare the prompt

Build the worker's prompt from the arguments. Include:

- **Task description**: what the worker should do
- **Task type**: if the task is investigation / analysis only (no code changes), explicitly state "report only, do not implement or commit" in the prompt so the worker doesn't over-reach into implementation
- **Issue context** (if an issue URL is provided): fetch details with `gh issue view` and include title, body, and URL so the worker can create a PR that closes it
- **Relevant context**: file paths, error messages, or reproduction steps the user mentioned

### 2. Launch the worker

```
Agent({
  name: "worker",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "<prepared prompt>\n\nIn your first report, include the absolute path of your worktree so the parent session can cd into it.\n\nSend your report to: main"
})
```

`Send your report to: main` — here `main` refers to the **parent session name** (the default name of the top-level Claude Code session), not a git branch. The worker uses this as the `to` field when calling SendMessage.

### 3. Follow the worker into its worktree

When the worker reports its worktree path, move the parent session into it so the user can inspect changes live:

```
EnterWorktree({ path: "<worker's worktree absolute path>" })
```

Notes:
- Pass `path` (not `name`) — this enters an existing worktree instead of creating a new one.
- The worker's branch is checked out there, so the user sees the modified code immediately.
- To return to the original directory later: `ExitWorktree({ action: "keep" })`. Use `"keep"` (not `"remove"`) — the worker still owns the worktree.

### 4. Communicate

- The worker reports progress via SendMessage. Review each report as it arrives.
- If fixes are needed, relay feedback via `SendMessage(to: "worker")`.
- If approved, tell the worker to proceed to deliver (commit & push, or PR if an issue was assigned).
- Once the worker reports completion (final report — e.g. "PR opened at ...", "commit pushed", or for investigation tasks "report ready"), send `SendMessage(to: "worker", message: {type: "shutdown_request"})`, then `ExitWorktree({ action: "keep" })` to return the session to the original directory. Do not wait for downstream events like PR merge — shut down once the worker's deliverable is in.
