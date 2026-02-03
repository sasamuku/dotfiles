---
name: commit
description: Creates logical, well-structured git commits following Conventional Commits. Use when user mentions commit, committing, saving changes, or asks to organize changes into commits.
disable-model-invocation: true
---

# Commit

Create logical, well-structured commits following Conventional Commits specification.

## Options

- `-y`: Skip user approval and proceed directly with commit creation

## Steps

### 1. Check Current Changes

```bash
git branch --show-current
git status
git diff
git diff --cached
```

### 2. Analyze Changes

- Group files by feature, module, or change type
- Identify the nature of each group (feat, fix, docs, chore, refactor, style, test, perf, build, ci)
- Determine appropriate commit order considering dependencies
- Ensure each commit is atomic and self-contained

### 3. Propose Commit Plan and Get User Approval

Present a commit plan following Conventional Commits format (no emojis):

```
Commit Plan:

1. feat(auth): add user authentication feature
   - apps/api/src/features/auth/login-usecase.ts
   - apps/api/src/features/auth/route.ts

2. test(auth): add authentication test cases
   - apps/api/src/features/auth/login-usecase.spec.ts

3. docs(api): update API documentation
   - docs/api/authentication.md

4. chore(deps): add authentication libraries
   - package.json
   - pnpm-lock.yaml

Do you approve this commit plan? (y/n)
If changes are needed, please specify what adjustments are required.
```

**IMPORTANT**: Wait for explicit user approval before proceeding to commit creation.

**Exception**: If the `-y` option is provided, skip the approval step and proceed directly to commit creation.

### 4. Type Check and Lint (Before Each Commit)

Before creating each commit, run type checking and linting:

```bash
npm run type-check || pnpm type-check || tsc --noEmit
npm run lint || pnpm lint
```

If errors are found, fix them before committing. If the project doesn't have these scripts, skip this step.

### 5. Create Commits in Logical Units

After approval, create each commit:

```bash
git add [related-files]
git commit -m "$(cat <<'EOF'
type(scope): concise subject line

- Detailed change description 1
- Detailed change description 2
- Detailed change description 3
EOF
)"
```

### 6. Commit Creation Principles

- **One commit, one purpose**: Follow single responsibility principle
- **Consider dependencies**: Commit in order that respects dependencies
- **Don't break builds**: Each commit should leave the codebase in a working state
- **Atomic commits**: Each commit should be self-contained and reversible
- **Clear messages**: Write descriptive commit messages that explain why, not just what

## Commit Types

- **feat(module)**: New feature
- **fix(module)**: Bug fix
- **docs(module)**: Documentation changes
- **chore(module)**: Maintenance tasks (dependencies, config, etc.)
- **refactor(module)**: Code refactoring without functionality changes
- **style(module)**: Code style changes (formatting, whitespace)
- **test(module)**: Adding or updating tests
- **perf(module)**: Performance improvements
- **build(module)**: Build system changes
- **ci(module)**: CI/CD configuration changes

## Commit Message Format

```
type(scope): subject

body (optional)

footer (optional)
```

- **type**: Required (feat, fix, docs, etc.)
- **scope**: Optional but recommended (module or component name)
- **subject**: Required, concise description in imperative mood
- **body**: Optional, detailed explanation with bullet points
- **footer**: Optional, breaking changes or issue references

**NO EMOJIS**: Use plain text only.

## Notes

- **No branch creation**: Do not create new branches during this command
- **Type check/lint only**: Do not run tests (user handles this separately)
- **Interactive**: Always confirm the plan with the user before executing (unless `-y` option is provided)
- **Strict format**: Follow Conventional Commits without emojis
- **One at a time**: Create commits sequentially, not in batch

## Arguments

$ARGUMENTS
