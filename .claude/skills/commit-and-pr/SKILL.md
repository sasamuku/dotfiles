---
name: commit-and-pr
description: Commit changes, push to remote, and create a draft pull request
disable-model-invocation: true
---

# Commit and PR

変更をコミットし、リモートへプッシュして、ドラフトプルリクエストを作成する。

## タスク

以下のワークフローを実行する:

1. **コミットを作成** - `/commit` スキルのワークフローに従う
2. **リモートへプッシュ** - `/push` スキルのワークフローに従う
3. **ドラフト PR を作成** - `/create-pr` スキルのワークフローに従う

詳細な手順は個別スキルを参照すること。
