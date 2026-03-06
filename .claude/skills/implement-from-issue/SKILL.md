---
name: implement-from-issue
description: End-to-end workflow from GitHub issue to reviewed code. Reads issue, creates plan, implements code, and iterates review-fix cycles until quality passes.
disable-model-invocation: true
argument-hint: [issue-number]
---

# Implement from Issue

Automate the full lifecycle: GitHub issue -> plan -> implement -> review.

## Arguments

Issue number (e.g., `123` or `#123`) or GitHub issue URL.

$ARGUMENTS

## Workflow

### Phase 1: Plan from Issue

Follow `@.claude/skills/plan-from-issue/SKILL.md` with the issue number from arguments.

### Phase 2: Implement Plan

Follow `@.claude/skills/implement-plan/SKILL.md` to implement all items from PLANS.md.

### Phase 3: Commit Changes

Follow `@.claude/skills/commit/SKILL.md` with the `-y` option to auto-approve commits.

### Phase 4: Review and Fix Loop

Repeat the following cycle up to 3 times:

1. Follow `@.claude/skills/review-code/SKILL.md` to review all changes
2. If **Critical** or **Warning** issues are found:
   - Fix the issues
   - Follow `@.claude/skills/commit/SKILL.md` with `-y` to commit fixes
   - Continue to next iteration
3. If no Critical/Warning issues remain, exit loop

### Completion

Print summary:
```
Done: Issue #<number> implemented and reviewed.
Review cycles: <count>
```
