---
name: merge
description: Merges a branch into current branch with conflict resolution. Use when user wants to merge, combine branches, or integrate changes.
disable-model-invocation: true
---

# Merge

ブランチを現在のブランチにマージする: $ARGUMENTS (既定値: origin main)。

## タスク

指定したブランチを現在のブランチへマージする。コンフリクトが発生したら解決する。

```bash
git merge $ARGUMENTS
# or default:
git merge origin main
```

コンフリクトが発生した場合は解消してからマージを完了する。
