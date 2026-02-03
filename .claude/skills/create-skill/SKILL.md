---
name: create-skill
description: Create a new Claude Code skill with best practices. Use when user wants to create a skill, add a SKILL.md, or extend Claude's capabilities.
disable-model-invocation: true
allowed-tools: Read, Write, Bash(mkdir *), WebFetch
---

# Create Skill

Create a new Claude Code skill following official best practices.

## Input
`$ARGUMENTS`

## Process

1. **Fetch latest documentation**
   First, read the official Skills documentation:
   ```
   WebFetch: https://code.claude.com/docs/en/skills
   ```

2. **Understand the user's intent**
   - Infer skill name and purpose from input
   - Skill name: lowercase, hyphens only (max 64 chars)
   - Determine if skill should be user-invocable, model-invocable, or both

3. **Decide skill type**
   - **Reference**: Background knowledge (conventions, patterns, domain info)
   - **Task**: Step-by-step workflow (deploy, commit, code generation)

4. **Create skill directory and SKILL.md**
   - Location: `.claude/skills/<skill-name>/SKILL.md`
   - Create directory first, then SKILL.md

## Key Decisions

### Invocation Control
| Setting | Effect |
|---------|--------|
| (default) | Both user and Claude can invoke |
| `disable-model-invocation: true` | Only user can invoke (for side effects) |
| `user-invocable: false` | Only Claude can invoke (background knowledge) |

### When to use `context: fork`
- For isolated execution in subagent
- For read-only exploration tasks
- For heavy research that shouldn't pollute main context

## SKILL.md Template

```yaml
---
name: skill-name
description: What this skill does and when to use it
# Optional fields below:
# disable-model-invocation: true  # Only manual invocation
# user-invocable: false          # Only Claude can invoke
# allowed-tools: Read, Grep      # Restrict tool access
# context: fork                  # Run in subagent
# agent: Explore                 # Agent type for fork
---

# Skill Title

Brief description of what this skill does.

## Task

Clear, step-by-step instructions.

Use `$ARGUMENTS` for user input.
Use `$0`, `$1` for positional args.
```

## Guidelines

- **Keep SKILL.md under 500 lines** - Move details to supporting files
- **Description is critical** - Claude uses it to decide when to apply
- **Start minimal** - Add complexity only when needed
- **Use `$ARGUMENTS`** - For dynamic user input
- **Supporting files** - Reference from SKILL.md, loaded when needed
