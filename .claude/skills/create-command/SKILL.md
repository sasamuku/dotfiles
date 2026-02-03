---
name: create-command
description: Create a new custom slash command with best practices
disable-model-invocation: true
allowed-tools: Read, Write, Bash(mkdir *)
---

# Create Command

Create a new custom slash command (skill).

## Arguments

$ARGUMENTS

## Process

### 1. Understand the User's Intent

- Infer appropriate command name and description
- Command name should be lowercase, hyphens only (max 64 chars)

### 2. Create the Skill

Location: `.claude/skills/<skill-name>/SKILL.md`

```bash
mkdir -p .claude/skills/<skill-name>
```

### 3. Write SKILL.md

## Template

```yaml
---
name: skill-name
description: What this skill does and when to use it
disable-model-invocation: true
---

# Skill Title

Brief description.

## Task

Clear, step-by-step instructions.

Use `$ARGUMENTS` for user input.
```

## Guidelines

- **Keep instructions concise** - Long instructions may be partially understood
- **Start simple** - Basic skills only need a Task section
- **Avoid over-specification** - Don't add allowed-tools unless necessary
- **Focus on clarity** - Simple, direct instructions work best
