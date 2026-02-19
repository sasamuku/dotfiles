---
name: handover
description: Generate a HANDOVER.md file summarizing the current session's work. Use at the end of a session to preserve context for the next session.
disable-model-invocation: true
---

# Handover

Generate a handover file to preserve session context for future sessions.

## Steps

### 1. Gather Context

Review the current session's conversation to identify:

- What was worked on
- Decisions made and their rationale
- Approaches that were tried but rejected
- Problems encountered and how they were resolved
- Lessons learned
- What remains to be done

### 2. Check for Changes

```bash
git status
git diff
git diff --cached
git log --oneline -10
```

### 3. Determine Save Location

Check if a `scratch/` directory exists at the project root:

- **If `scratch/` exists**: Save as `scratch/<descriptive-name>.md` (e.g. `scratch/auth-refactor-handover.md`). Choose a name that reflects the session's work.
- **If `scratch/` does not exist**: Save as `HANDOVER.md` at the project root.

### 4. Generate Handover File

Write the handover file with the following sections:

```markdown
# Handover

## What was done
- [Completed work items with brief descriptions]

## Decisions
- [Design decisions and their rationale]

## Rejected approaches
- [Approaches considered but not adopted, with reasons]

## Gotchas
- [Problems encountered and their solutions]

## Learnings
- [Key insights gained during the session]

## Next steps
- [Remaining work items, in priority order]

## Related files
- [Files that were created or modified]
```

### 5. Confirm

Show the generated content to the user for review.

## Notes

- Keep each section concise; bullet points only
- Omit empty sections
- Focus on information that would be lost when context resets
- The handover file is for session-specific context; project-level rules belong in `CLAUDE.md`
- `scratch/` is gitignored but shared across worktrees, making it ideal for handover files

$ARGUMENTS
