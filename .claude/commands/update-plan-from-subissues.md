---
description: Update PLANS.md content based on linked sub-issues status
---

## Task

Update PLANS.md by analyzing linked sub-issues and reflecting their current state into existing sections without adding new sections.

### Process

1. **Read PLANS.md frontmatter**:
   - Extract `issue:` field (parent issue number)
   - If not found, exit with error

2. **Fetch sub-issues from parent**:
   ```bash
   gh api repos/{owner}/{repo}/issues/{issue}/sub_issues --jq '.[] | {number, title, state}'
   ```

3. **Analyze sub-issues and PLANS.md content**:
   - Read each sub-issue details: `gh issue view {sub-issue-number} --json number,title,body,state`
   - Compare sub-issue information with existing PLANS.md sections
   - Identify what needs updating:
     - **Validation & Acceptance Criteria**: Mark completed items based on closed sub-issues
     - **Open Questions**: Remove questions that are resolved by sub-issues
     - **Discoveries & Insights**: Add findings from sub-issue discussions
     - **Decision Log**: Add decisions made in sub-issues
     - **Follow-up Issues**: Update with new sub-issues

4. **Update PLANS.md intelligently**:
   - Use Edit tool to update existing content
   - Convert relevant information from sub-issues into PLANS.md format
   - Mark checkboxes `- [x]` for completed sub-issues
   - Keep existing structure and sections unchanged

5. **Sync to GitHub** (optional, ask user):
   - After updating PLANS.md, offer to run `/sync-plan`

### Guidelines

- Do NOT add new sections to PLANS.md
- Do NOT duplicate information that's already current
- Only update content that needs reflection of sub-issue progress
- Preserve PLANS.md's existing narrative and structure
- Use sub-issue discussions as evidence for updates

### Arguments

$ARGUMENTS
