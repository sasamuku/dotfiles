---
name: push
description: Pushes commits to remote repository. Use when user wants to push, upload commits, or send changes to remote.
disable-model-invocation: true
---

# Push

Push commits to remote repository.

## Task

Push the current branch commits to the remote repository.

```bash
git push
```

If upstream is not set:

```bash
git push -u origin $(git branch --show-current)
```
