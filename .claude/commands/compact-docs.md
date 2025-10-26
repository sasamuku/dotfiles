---
description: Compression command to reduce documentation redundancy and improve clarity
allowed-tools: Read, Edit
---

## Task: Documentation Compression and Optimization

### Input
`$ARGUMENTS` - Path to the markdown file to be compressed

### Processing Flow

1. **Read and Analyze Target Document**
   - Understand overall structure and content
   - Comprehend relationships between sections

2. **Apply Compression Techniques**

   **A. Reduce Duplicate Information**
   - Identify content repeated across sections
   - Convert duplicates to cross-references (e.g., "See section X for details")
   - Unify different expressions of the same concept

   **B. Simplify Verbose Explanations**
   - Convert long text to bullet points
   - Summarize excessive details while retaining important information
   - Improve information density without losing meaning
   - Prioritize concise and clear expressions over detailed explanations

   **C. Detect Contradictions**
   - Identify inconsistencies between sections
   - Report contradictory statements or information
   - Point out content inconsistencies (do not auto-fix)

   **D. Remove Historical Information**
   - Remove change history and update timestamps
   - Delete historical descriptions like "Added ~" or "Changed to ~"
   - Document history is unnecessary since git tracks changes

3. **Generate Compression Report**
   Include:
   - Applied compression techniques and specific examples
   - Line count before/after compression and reduction rate
   - Detected contradictions (if any)
   - Recommended next actions (if necessary)

### Guidelines

- **Preserve Meaning** - Don't sacrifice information quality for brevity
- **Maintain Structure** - Keep the original document organization
- **Be Explicit** - Show what was changed and why
- **Don't Auto-fix Contradictions** - Report them for manual review

### Output Format

Display the compression report first, then apply edits to the file.
