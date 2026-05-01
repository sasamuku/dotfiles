---
name: plan-from-issue
description: End-to-end workflow that reads a GitHub issue, creates PLANS.md, and syncs it back to the issue comment. Combines read-issue, create-plan, and sync-plan into a single command.
disable-model-invocation: true
---

# Plan from Issue

GitHub Issue を読み込み、PLANS.md を作成し、Issue に同期する — これらを 1 ステップで実行する。

## 引数

Issue 番号 (例: `123` または `#123`) または GitHub Issue の URL。

$ARGUMENTS

## ワークフロー

以下の 3 つのスキルを順番に実行する:

### フェーズ 1: Issue の読み込み

引数の Issue 番号を使い、`/read-issue` スキルのワークフローに従う。

### フェーズ 2: PLANS.md の作成

フェーズ 1 で収集した Issue 情報を使い、`/create-plan` スキルのワークフローに従う。

### フェーズ 3: Issue への同期

`/sync-plan` スキルのワークフローに従い、PLANS.md を Issue に投稿する。

完了したら以下を表示する:
```
Done: Issue #<number> read, PLANS.md created, synced to issue.
```
