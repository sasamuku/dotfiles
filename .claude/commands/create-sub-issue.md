---
description: Create a sub-issue linked to a parent GitHub issue
---

## Task

Create a sub-issue linked to a parent GitHub issue using the sub-issue API.

### Process

1. **Get parent issue context**:
   - From arguments: Extract issue reference (`#123`, `123`, or URL)
   - From context: Check PLANS.md frontmatter or recent conversation
   - Fetch: `gh issue view <issue-number> --json number,title,body,url`
   - Find PLANS_SYNC_MARKER comment for detailed context

2. **Create sub-issue** (follow create-issue.md guidelines):
   - Check `.github/ISSUE_TEMPLATE` and use appropriate template
   - **REQUIRED**: Start body with `Part of #{parent-issue-number}`
   - Create focused, actionable issue based on parent context

3. **Link to parent**:
   ```bash
   ISSUE_URL=$(gh issue create --title "$TITLE" --body "$BODY" --label "sub-issue")
   ISSUE_NUMBER=$(echo $ISSUE_URL | grep -o '[0-9]*$')
   # IMPORTANT: Use .id (integer), NOT .node_id (string)
   # The sub_issue_id parameter requires an integer ID
   SUB_ISSUE_ID=$(gh api /repos/{owner}/{repo}/issues/$ISSUE_NUMBER --jq .id)
   gh api --method POST /repos/{owner}/{repo}/issues/{parent-number}/sub_issues \
     -F "sub_issue_id=$SUB_ISSUE_ID"
   ```

4. **Order multiple sub-issues** (if creating several):
   ```bash
   gh api --method PATCH /repos/{owner}/{repo}/issues/{parent-number}/sub_issues/priority \
     --input - <<< '{"sub_issue_id": '$SUB_ISSUE_ID', "after_id": '$PREV_SUB_ISSUE_ID'}'
   ```

### Body Format

```markdown
Part of #{parent-issue-number}

[Template content or standard structure]
```

### Arguments

Accepts:
- Parent issue number (e.g., `123` or `#123`)
- Parent issue URL
- Sub-issue description or prompt (optional - will be inferred from context if not provided)

$ARGUMENTS

### Best Practices

- Use parent issue body + PLANS_SYNC_MARKER comment for full context
- Keep sub-issues focused and independently completable
- Apply consistent labels (`sub-issue`, area labels)
- Consider logical execution order when creating multiple sub-issues
