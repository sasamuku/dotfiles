---
name: handover
description: Generate a HANDOVER.md file summarizing the current session's work. Use at the end of a session to preserve context for the next session.
disable-model-invocation: true
---

# Handover

Generate a `HANDOVER.md` at the project root to preserve session context for future sessions.

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

### 3. Generate HANDOVER.md

Write `HANDOVER.md` at the project root with the following sections:

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

### 4. Confirm

Show the generated content to the user for review.

## Notes

- Keep each section concise; bullet points only
- Omit empty sections
- Focus on information that would be lost when context resets
- `HANDOVER.md` is for session-specific context; project-level rules belong in `CLAUDE.md`

$ARGUMENTS
