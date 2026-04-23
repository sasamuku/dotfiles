---
name: push
description: Pushes commits to remote repository. Use when user wants to push, upload commits, or send changes to remote.
disable-model-invocation: true
---

# Push

コミットをリモートリポジトリにプッシュする。

## タスク

現在のブランチのコミットをリモートリポジトリへプッシュする。

```bash
git push
```

upstream が未設定の場合:

```bash
git push -u origin $(git branch --show-current)
```
