# Fixup Commit Command

This slash command creates a fixup commit for a specified target commit and performs an interactive rebase with autosquash.

## Arguments

- `$ARGUMENTS`: The target commit hash to fixup

## Execution Steps

### 1. Validate Arguments

Check if the commit hash argument is provided:

```bash
# $ARGUMENTS should contain the target commit hash
```

If no argument is provided, ask the user for the target commit hash.

### 2. Check Current Changes

Gather information about the current state:

```bash
git status                 # Check changed files
git diff                   # Check unstaged changes
git diff --cached          # Check staged changes
git log --oneline -10      # Show recent commits for reference
```

### 3. Get Target Commit Information

Retrieve the target commit message:

```bash
git log --format="%H %s" -1 <target-commit>
```

### 4. Present Confirmation

Display the following information and ask for confirmation:

```
Fixup Commit Plan:

Target commit: <commit-hash>
Commit message: <commit-message>

Files to be included in fixup:
- <file1>
- <file2>
- ...

This will:
1. Stage all changes (if not already staged)
2. Create a fixup commit for the target
3. Run interactive rebase with autosquash

Proceed? (y/n)
```

**IMPORTANT**: Wait for explicit user approval (y) before proceeding.

### 5. Execute Fixup

After user approval:

```bash
# Stage all changes if not already staged
git add -A

# Create fixup commit
git commit --fixup=<target-commit>

# Show rebase plan (for verification)
GIT_SEQUENCE_EDITOR="cat" git rebase -i --autosquash main --no-edit 2>/dev/null || true

# Execute rebase with autosquash
git rebase -i --autosquash main
```

### 6. Verify Result

After rebase completes:

```bash
git log --oneline -10      # Show recent commits to verify
```

## Notes

- **Requires clean working tree or staged changes**: Unstaged changes will be staged automatically
- **Target commit must exist**: The command will fail if the commit hash is invalid
- **Rebase onto main**: The rebase is performed onto the main branch
- **Interactive confirmation**: Always confirm with the user before executing
