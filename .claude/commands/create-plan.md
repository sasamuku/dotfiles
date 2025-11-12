---
description: Create a PLANS.md execution plan document for project management
---

## Task

Create a comprehensive PLANS.md file in the project root directory to track project execution.

### Input Handling

If the arguments contain a GitHub issue reference:
1. Extract the issue number from arguments (format: `#123`, `123`, or GitHub URL)
2. Use `gh issue view <issue-number> --json number,title,body,url` to fetch the issue details
3. Understand the requirements and context from the issue
4. Search the codebase for relevant files if needed
5. Use the issue information to populate the PLANS.md sections
6. Add frontmatter with issue metadata (see Frontmatter section below)
7. After creating PLANS.md, post initial sync comment to the issue

### Frontmatter (when Issue-linked)

When creating a PLANS.md linked to an issue, add this frontmatter at the top:

```yaml
---
issue: 123
issue_url: https://github.com/owner/repo/issues/123
last_synced: 2025-11-12T10:30:00Z
---
```

- `issue`: Issue number
- `issue_url`: Full GitHub URL to the issue
- `last_synced`: ISO 8601 timestamp of last sync (use `date -u +"%Y-%m-%dT%H:%M:%SZ"`)

### Structure

The PLANS.md should include these sections:

1. **Purpose / Overview**

   - Project goal summary
   - Core value proposition
   - What problem this solves

2. **Context & Direction**

   - Problem background
   - Design philosophy
   - Key constraints

3. **Validation & Acceptance Criteria**

   - Testable acceptance criteria
   - Test scenarios
   - Success metrics

4. **Specification**

   - System specifications
   - Architecture decisions
   - Design details

5. **Open Questions**

   - Unresolved questions
   - Options under consideration
   - Blockers and uncertainties

6. **Discoveries & Insights**

   - Technical discoveries
   - Implementation learnings
   - Unexpected findings

7. **Decision Log**

   - Key decisions with dates
   - Rationale and context
   - Trade-offs considered

8. **Outcomes & Retrospectives**

   - Milestone results
   - Lessons learned
   - What went well / could improve

9. **Follow-up Issues**

   - Future work items
   - Out-of-scope tasks
   - Technical debt

### Guidelines

- Start with information gathered from the current project context
- Use the user's input to understand the project scope
- Keep it concise but comprehensive
- Format as a living document that can evolve
- Use markdown checkboxes `- [ ]` for trackable tasks

### Issue Comment Sync (when Issue-linked)

After creating PLANS.md with issue frontmatter, post a comment to the issue:

1. Get repository info: `gh repo view --json owner,name`
2. Generate sync marker with timestamp
3. Post comment with marker + PLANS.md content (excluding frontmatter):

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$(tail -n +5 PLANS.md)"  # Skip frontmatter (lines 1-4)

gh issue comment <issue-number> --body "$CONTENT"
```

The sync marker format: `<!-- PLANS_SYNC_MARKER:2025-11-12T10:30:00Z -->`

This allows `/sync-plan` to find and update this comment later.

### Arguments

Accepts:
- Project description or context (free text)
- GitHub issue number (e.g., `123` or `#123`)
- GitHub issue URL

$ARGUMENTS
