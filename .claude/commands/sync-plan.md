---
description: Sync PLANS.md content to linked GitHub issue comment
---

## Task

Synchronize the current PLANS.md file with its linked GitHub issue by updating the comment containing the execution plan.

## Prerequisites

- PLANS.md must exist in the project root
- PLANS.md must have frontmatter with `issue:` field (created by `/create-plan <issue>`)

## Workflow

### 1. Read Issue Metadata from PLANS.md

Extract from frontmatter:
- `issue`: Issue number
- `issue_url`: GitHub issue URL (for reference)

If no `issue:` field found, exit with error:
```
Error: No issue linked to PLANS.md
Create an issue-linked plan with: /create-plan <issue-number>
```

### 2. Get Repository Information

```bash
gh repo view --json owner,name
```

Extract `owner` and `name` for API calls.

### 3. Find Existing Sync Comment

Use GitHub API to list all comments on the issue:

```bash
gh api repos/{owner}/{name}/issues/{issue}/comments --jq '.[] | select(.body | contains("PLANS_SYNC_MARKER")) | .id'
```

This searches for comments containing `<!-- PLANS_SYNC_MARKER:... -->` and returns the comment ID.

### 4. Update or Create Comment

Generate new timestamp and content:

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$(tail -n +5 PLANS.md)"  # Exclude frontmatter (first 4 lines: ---, issue:, issue_url:, last_synced:, ---)
```

**If comment exists** (ID found in step 3):
```bash
gh api -X PATCH repos/{owner}/{name}/issues/comments/{comment_id} \
  -f body="$CONTENT"
```

**If no comment exists**:
```bash
gh issue comment {issue} --body "$CONTENT"
```

### 5. Update PLANS.md Frontmatter

Update the `last_synced` field in PLANS.md with the new timestamp:

```bash
sed -i '' "s/^last_synced: .*/last_synced: ${TIMESTAMP}/" PLANS.md
```

(Note: macOS uses `sed -i ''`, Linux uses `sed -i`)

### 6. Confirm Success

Output confirmation message:
```
✓ Synced PLANS.md to issue #123
  Comment ID: 1234567890
  Timestamp: 2025-11-12T10:30:00Z
  URL: https://github.com/owner/repo/issues/123#issuecomment-1234567890
```

## Error Handling

- **No PLANS.md found**: Exit with error message
- **No issue in frontmatter**: Exit with error message
- **gh command fails**: Show error output from gh
- **Issue is closed**: Warn but continue (user may want to update closed issues)

## Notes

- The sync is one-directional: PLANS.md → GitHub Issue
- Manual edits to the GitHub comment will be overwritten on next sync
- The sync marker allows `/sync-plan` to be idempotent (same comment is updated repeatedly)
