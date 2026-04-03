# Workflow Rules

## Branch Safety

**If the current branch is `main` or `master`, always ask the user for clarification before making any code changes.**

- Confirm the intent and gather details about the requested changes
- Suggest using the `/delegate-worker` skill to work in an isolated worktree
- Never modify code directly on the `main` branch

---

# Core Principles: **Less is More**

- **Keep implementations small** - *Write the smallest, most obvious solution*
- **Let code speak** - *If you need multi-paragraph comments, refactor until intent is obvious*
- **Simple > Clever** - *Clear code beats clever code every time*
- **Delete ruthlessly** - *Remove anything that doesn't add clear value*
