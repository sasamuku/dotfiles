---
name: implement-from-plan
description: Implement features from PLANS.md using the plan-driven-coder agent
disable-model-invocation: true
context: fork
agent: plan-driven-coder
---

# Implement Plan

## Arguments

$ARGUMENTS

If no arguments provided, implement the next uncompleted item.

## Constraints

- Do NOT commit changes. Leave all changes unstaged.
- After implementation, follow `@.claude/skills/review-code/SKILL.md` to review all changes.
- Report review findings to the user before they decide to commit.
