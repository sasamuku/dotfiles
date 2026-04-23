---
name: rebase
description: Rebases current branch onto target with conflict resolution. Use when user wants to rebase, update branch base, or linearize history.
disable-model-invocation: true
---

# Rebase

$ARGUMENTS で指定したブランチを fetch し、現在のブランチをリベースする (既定値: origin/main)。

## タスク

現在のブランチを指定ブランチへリベースする。コンフリクトが発生したら解決する。

```bash
git fetch origin
git rebase $ARGUMENTS
# or default:
git rebase origin/main
```

コンフリクトが発生した場合は解消してからリベースを継続する。
