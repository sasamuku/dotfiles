---
name: plan-from-issue
description: End-to-end workflow that reads a GitHub issue, creates PLANS.md, and syncs it back to the issue comment. Combines read-issue, create-plan, and sync-plan into a single command.
disable-model-invocation: true
---

# Plan from Issue

Read a GitHub issue, create PLANS.md, and sync it back to the issue — all in one step.

## Arguments

Issue number (e.g., `123` or `#123`) or GitHub issue URL.

$ARGUMENTS

## Workflow

Execute the following three skills in sequence:

### Phase 1: Read Issue

Follow `@.claude/skills/read-issue/SKILL.md` with the issue number from arguments.

### Phase 2: Create PLANS.md

Follow `@.claude/skills/create-plan/SKILL.md` using the issue information gathered in Phase 1.

### Phase 3: Sync to Issue

Follow `@.claude/skills/sync-plan/SKILL.md` to post PLANS.md back to the issue.

Print confirmation when done:
```
Done: Issue #<number> read, PLANS.md created, synced to issue.
```
