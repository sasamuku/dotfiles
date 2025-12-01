---
description: Fetch and read a GitHub issue using gh command
---

## Task

Use the `gh` command to fetch the GitHub issue specified in the arguments and present its contents for analysis, including any linked sub-issues.

### Steps
1. Extract the issue number from the arguments (format: `#123` or just `123`)
2. Use `gh issue view <issue-number> --json number,title,body,state,url,comments` to fetch the issue details including all comments
3. Parse the issue body to find sub-issues:
   - Look for task list patterns: `- [ ] #123` or `- [x] #456`
   - Extract all sub-issue numbers
4. For each sub-issue found, fetch its details:
   - Use `gh issue view <sub-issue-number> --json number,title,body,state,url`
   - Include sub-issue information in the analysis
5. Understand the problem described in the parent issue and sub-issues
6. Search the codebase for relevant files related to the issues
7. Present the issue information in a structured format:
   - Parent issue summary
   - Sub-issues list with their status (open/closed)
   - Relevant code context

### Arguments
The command accepts an issue number (e.g., `123` or `#123`)

$ARGUMENTS
