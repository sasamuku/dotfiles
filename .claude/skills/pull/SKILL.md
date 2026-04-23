---
name: pull
description: Pulls latest changes from remote with conflict resolution. Use when user wants to pull, fetch changes, or update from remote.
disable-model-invocation: true
---

# Pull

$ARGUMENTS で指定したブランチから最新の変更を取り込む (既定値: origin main)。

## タスク

最新の変更を取得し、マージする。コンフリクトが発生したら解決する。

```bash
git pull $ARGUMENTS
# or default:
git pull origin main
```

コンフリクトが起きた場合は分析・解決してからマージを完了する。
