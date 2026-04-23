---
name: squash-commits
description: Review all changes (commits and working changes) and organize into appropriate commit granularity
disable-model-invocation: true
---

# Squash Commits

すべての変更を、適切な粒度のコミットへ整理し直す。

## 手順

### 1. 現状を確認する

```bash
git status
git diff
git diff --staged
git log origin/main..HEAD --oneline
git log origin/main..HEAD
```

### 2. 分析し、最適なコミット構造を決める

- コミットと作業ディレクトリにまたがる関連変更をまとめる
- 分離すべき論理単位を特定する
- 適切なコミット粒度 (論理変更ごとに 1 コミット) を意識する
- まとめる/分割する対象を決める
- 各論理単位に対し、分かりやすいコミットメッセージを決める

### 3. 再編成を実行する

- 作業ツリーに変更があれば、一時コミットや stash で退避する
- 対話的リベースで既存コミットを並べ替える
- 作業変更を `git commit --amend` または新規コミットとして適切なコミットへ反映する
- 最終的なコミット履歴がクリーンで論理的であることを確認する
- 完了後に結果を表示する

ユーザーの承認なしに、最適な粒度でコミットを自動的に再編成する。
