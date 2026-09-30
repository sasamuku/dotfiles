---
name: create-issue
description: Draft and create a GitHub issue using repository templates and user-approved content.
disable-model-invocation: true
---

# Create Issue

引数: $ARGUMENTS。未指定なら会話から起票内容を整理する。

1. 対象リポジトリと `.github/ISSUE_TEMPLATE/` を確認し、適切なテンプレートを優先する。
2. 現状・目標・調査根拠・実装案・依存関係・影響を整理する。タイトルは簡潔にし、Conventional Commits形式にしない。
3. テンプレートがなければ Overview / Current state / Investigation results / Action items / Impact analysis / Technical considerations で本文を作る。根拠はファイル・行へのリンクで示す。
4. タイトル・本文を提示し、**作成前にユーザー承認を得る**。
5. 承認済み本文を一時ファイルへ保存し、`gh issue create --repo <owner>/<repo> --title "<title>" --body-file <file>` で作成する。IssueのURLを報告する。
