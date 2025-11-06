---
description: Create a PLANS.md execution plan document for project management
---

## Task

Create a comprehensive PLANS.md file in the project root directory to track project execution.

### Input Handling

If the arguments contain a GitHub issue reference:
1. Extract the issue number from arguments (format: `#123`, `123`, or GitHub URL)
2. Use `gh issue view <issue-number>` to fetch the issue details
3. Understand the requirements and context from the issue
4. Search the codebase for relevant files if needed
5. Use the issue information to populate the PLANS.md sections

### Structure

The PLANS.md should include these sections:

1. **Purpose / Big Picture**

   - Project goal summary
   - User benefits
   - Expected user-visible behavior

2. **Initial Requirements & Scope**

   - High-level requirements
   - Key features list
   - In-scope vs. out-of-scope items

3. **Milestones & Deliverables**

   - Work phases breakdown
   - Specific deliverables
   - Acceptance criteria

4. **Progress**

   - Checkbox task list for granular tracking
   - Completion status
   - Progress dates

5. **Surprises & Discoveries**

   - Unexpected learnings
   - Technical challenges
   - New insights

6. **Decision Log**

   - Key decisions with dates
   - Reasoning and context
   - Supporting references

7. **Outcomes & Retrospectives**
   - Milestone results
   - Lessons learned
   - What went well / could improve

### Guidelines

- Start with information gathered from the current project context
- Use the user's input to understand the project scope
- Keep it concise but comprehensive
- Format as a living document that can evolve
- Use markdown checkboxes `- [ ]` for trackable tasks

### Arguments

Accepts:
- Project description or context (free text)
- GitHub issue number (e.g., `123` or `#123`)
- GitHub issue URL

$ARGUMENTS
