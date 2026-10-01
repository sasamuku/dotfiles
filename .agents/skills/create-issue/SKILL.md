---
name: create-issue
description: Draft and create a GitHub issue using repository templates and user-approved content.
disable-model-invocation: true
---

# Create Issue

引数: $ARGUMENTS。未指定なら会話から起票内容を整理する。

1. 対象リポジトリと `.github/ISSUE_TEMPLATE/` を確認し、適切なテンプレートを優先する。
2. タイトル・本文を作成して提示し、**作成前にユーザー承認を得る**。
3. 承認済み本文を一時ファイルへ保存し、`gh issue create --repo <owner>/<repo> --title "<title>" --body-file <file>` で作成する。IssueのURLを報告する。
