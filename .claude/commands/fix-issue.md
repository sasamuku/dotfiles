---
description: Fetch and read a GitHub issue, then implement and verify the fix
---

## Task

Use the `gh` command to fetch the GitHub issue specified in the arguments, analyze the problem, implement the necessary changes, and verify the fix is complete.

### Steps
1. Extract the issue number from the arguments (format: `#123` or just `123`)
2. Use `gh issue view <issue-number>` to fetch the issue details
3. Understand the problem described in the issue
4. Search the codebase for relevant files related to the issue
5. Implement the necessary changes to fix the issue
6. Write and run tests to verify the fix
7. Ensure code passes linting and type checking (use `pnpm lint`)
8. Create a descriptive commit message following the project's commit conventions

### Arguments
The command accepts an issue number (e.g., `123` or `#123`)
