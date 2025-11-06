---
description: General guidelines for creating GitHub issues
---

## Task
Create a new issue in a GitHub repository using the GitHub CLI.

### Process
1. **Check for issue templates**: Look for `.github/ISSUE_TEMPLATE` directory
   - If templates exist, list available templates and select the most appropriate one
   - Use `gh issue create --template <template-name>` to follow the template format
   - If no templates exist, proceed with standard format
2. **Analyze the request**: First, understand the context and technical implications
3. **Gather information**: If the issue involves technical implementation, think through:
   - Current state vs desired state
   - Technical requirements and dependencies
   - Potential implementation approaches
   - Impact and risks
4. **Structure the issue**: Create a well-structured issue with:
   - Clear title
   - Detailed body with background, requirements, and technical considerations
   - Use proper markdown formatting
   - Follow template format if available

### Arguments
$ARGUMENTS

**Argument Handling**:
- When arguments are provided: Create an issue based on the given content
- When arguments are empty: Detect technical discussions from recent conversation and suggest creating an issue based on that context
- When instructed to "create from conversation": Analyze conversation history to generate an issue

### Best Practices
- **Argument validation**: When arguments are empty, first analyze available conversation context
- **Conversation history utilization**: Auto-detect technical investigations, bug discoveries, refactoring proposals
- **Research integration**: Use code investigation and search results as evidence for the issue
- **Structured issues**: Include the following sections:
  - Overview (problem summary)
  - Current state (technical current situation)
  - Investigation results (detailed research findings)
  - Action items (specific work to be done)
  - Impact analysis (risks and benefits)
  - Technical considerations (implementation notes)
- **Evidence documentation**: Include specific file paths, line numbers, and search results

