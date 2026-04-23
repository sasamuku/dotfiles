---
name: read-issue
description: Fetch and read a GitHub issue using gh command
disable-model-invocation: true
---

# Read Issue

GitHub の Issue を取得し、サブ Issue と併せて表示する。

## 引数

Issue 番号 (例: `123` または `#123`)

$ARGUMENTS

## 手順

1. 引数から Issue 番号を抽出する
2. Issue の詳細を取得する:
   ```bash
   gh issue view <issue-number> --json number,title,body,state,url,comments
   ```
3. Issue 本文をパースし、**すべて** のサブ Issue を抽出する:
   - タスクリスト記法: `- [ ] #123`, `- [x] #456`
   - 直接の Issue 参照: `#123`
   - Markdown リンク: `[text](#123)`
4. 見つかった **各** サブ Issue の詳細を取得する:
   ```bash
   gh issue view <sub-issue-number> --json number,title,body,state,url
   ```
5. 関連ファイルをコードベースから検索する
6. Issue 情報を提示する:
   - 親 Issue のサマリ
   - サブ Issue 一覧 (オープン / クローズ状態付き)
   - 関連するコードのコンテキスト
