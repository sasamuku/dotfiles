---
name: sentry-investigate
description: Investigate Sentry issues by URL. Use when user provides a Sentry issue URL and wants to understand the error cause, analyze stack traces, and find the root cause in the codebase.
argument-hint: <sentry-issue-url>
allowed-tools: mcp__sentry__get_issue_details, mcp__sentry__analyze_issue_with_seer, mcp__sentry__get_issue_tag_values, mcp__sentry__search_issue_events, Read, Grep, Glob
---

# Sentry Issue Investigation

Sentry の Issue を調査し、コードベース内の根本原因を特定する。

## 入力

Sentry Issue URL: `$ARGUMENTS`

## プロセス

### ステップ 1: Issue の詳細を取得する

提供された URL を使い `mcp__sentry__get_issue_details` を呼び出す:

```
mcp__sentry__get_issue_details(issueUrl='$ARGUMENTS')
```

以下の情報を抽出する:
- エラーメッセージとエラー種別
- スタックトレース (ファイルパス、行番号、関数名)
- 初回/最終発生日時
- イベント数とユーザーへの影響

### ステップ 2: AI による根本原因分析 (オプション)

より深い分析が必要な場合は Seer を使う:

```
mcp__sentry__analyze_issue_with_seer(issueUrl='$ARGUMENTS')
```

これにより以下が得られる:
- AI による根本原因分析
- 具体的なコード修正の提案
- 実装のガイダンス

### ステップ 3: 関連コードを見つける

スタックトレースを基にコードベースを検索する:

1. **エラー発生元のファイルを特定する** — Glob を使いスタックトレースに記載されたファイルを見つける
2. **問題のコードを読む** — 特定の行・関数を読む
3. **コールチェーンを追う** — スタックトレースに沿ってコードベースをたどる
4. **関連コードを確認する** — 類似のパターンや共通ユーティリティを調べる

### ステップ 4: 調査結果を報告する

以下をまとめる:
1. **Issue の概要** — エラー種別、発生頻度、ユーザーへの影響
2. **根本原因** — エラーの原因
3. **影響を受けるコード** — このコードベース内のファイルパスと行番号
4. **修正案** — Issue を解消するための具体的なコード変更

## 注意事項

- URL が無効な場合、またはアクセスが拒否された場合は、URL や組織名が正しいか確認する
- エラーメッセージの単純な言い換えではなく、実行可能な指摘に集中する
- 調査結果はコードベース内の具体的な箇所 (ファイルパス・行番号) に紐づける
