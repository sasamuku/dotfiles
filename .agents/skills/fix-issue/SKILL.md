---
name: fix-issue
description: Fetches a GitHub issue, implements the fix, and verifies it. Use when user wants to fix an issue, implement issue changes, or resolve a bug.
disable-model-invocation: true
---

# Fix Issue

GitHub の Issue を取得し、修正を実装し、検証する。

## 引数

Issue 番号 (例: `123` または `#123`)

$ARGUMENTS

## 手順

1. 引数から Issue 番号を抽出する
2. Issue の詳細を取得する:
   ```bash
   gh issue view <issue-number>
   ```
3. Issue で説明されている問題を把握する
4. 関連ファイルをコードベースから検索する
5. 必要な変更を実装する
6. テストを書き、実行して修正を検証する
7. プロジェクトに存在する場合は、リンタ・型チェックを実行する
8. Conventional Commits に沿った分かりやすいコミットメッセージを作成する
