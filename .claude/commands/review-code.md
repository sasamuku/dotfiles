---
description: Review local code changes against main branch
---

## Task

Review all uncommitted and committed changes on the current branch compared to main.

### Steps

1. Get the diff between main and current HEAD:
   ```bash
   git diff main...HEAD
   ```

2. Get commit history for context:
   ```bash
   git log main..HEAD --oneline
   ```

3. If there are uncommitted changes, also get:
   ```bash
   git diff
   git diff --cached
   ```

4. Use **code-reviewer** agent to perform the review with all gathered diff information

### Output

The code-reviewer agent will provide structured feedback organized by priority (Critical, Warning, Suggestion) with specific file locations and fix recommendations.
