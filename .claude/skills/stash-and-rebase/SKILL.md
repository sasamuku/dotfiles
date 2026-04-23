---
name: stash-and-rebase
description: Stash changes, rebase onto latest main, and reapply stash
disable-model-invocation: true
---

# Stash and Rebase

変更を stash し、最新の main へリベースしてから stash を適用し直す。

## 手順

1. 追跡外ファイルも含め、現在の変更をすべて stash する:
   ```bash
   git stash push -u -m "Auto-stash before rebase"
   ```

2. リモートから最新の変更を fetch する:
   ```bash
   git fetch origin
   ```

3. 現在のブランチを最新の main へリベースする:
   ```bash
   git rebase origin/main
   ```

4. stash した変更を再適用する:
   ```bash
   git stash pop
   ```

リベース中にコンフリクトが発生した場合は、処理を一時停止し、ユーザーに通知してコンフリクトの解決を促し、解決後に stash pop を実行する。
