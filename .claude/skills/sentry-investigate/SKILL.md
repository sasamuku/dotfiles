---
name: sentry-investigate
description: Investigate Sentry issues by URL. Use when user provides a Sentry issue URL and wants to understand the error cause, analyze stack traces, and find the root cause in the codebase.
argument-hint: <sentry-issue-url>
allowed-tools: mcp__sentry__get_issue_details, mcp__sentry__analyze_issue_with_seer, mcp__sentry__get_issue_tag_values, mcp__sentry__search_issue_events, Read, Grep, Glob
---

# Sentry Issue Investigation

Investigate a Sentry issue and identify the root cause in the codebase.

## Input

Sentry issue URL: `$ARGUMENTS`

## Process

### Step 1: Get Issue Details

Use `mcp__sentry__get_issue_details` with the provided URL:

```
mcp__sentry__get_issue_details(issueUrl='$ARGUMENTS')
```

Extract key information:
- Error message and type
- Stack trace (file paths, line numbers, function names)
- First/last seen timestamps
- Event count and user impact

### Step 2: AI Root Cause Analysis (Optional)

If the issue needs deeper analysis, use Seer:

```
mcp__sentry__analyze_issue_with_seer(issueUrl='$ARGUMENTS')
```

This provides:
- AI-powered root cause analysis
- Specific code fix suggestions
- Implementation guidance

### Step 3: Find Relevant Code

Based on the stack trace, search the codebase:

1. **Locate error source files** - Use Glob to find files mentioned in stack trace
2. **Read the problematic code** - Read the specific lines/functions
3. **Trace the call chain** - Follow the stack trace through the codebase
4. **Check related code** - Look for similar patterns or shared utilities

### Step 4: Report Findings

Summarize:
1. **Issue overview** - Error type, frequency, user impact
2. **Root cause** - What's causing the error
3. **Affected code** - File paths and line numbers in this codebase
4. **Suggested fix** - Specific code changes to resolve the issue

## Notes

- If the URL is invalid or access denied, ask for correct URL or organization
- Focus on actionable findings, not just restating error messages
- Link findings to specific code locations in the codebase
