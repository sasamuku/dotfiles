---
name: sentry-investigate
description: Investigate a Sentry issue URL and trace its root cause in the codebase.
argument-hint: <sentry-issue-url>
allowed-tools: mcp__sentry__get_issue_details, mcp__sentry__analyze_issue_with_seer, mcp__sentry__get_issue_tag_values, mcp__sentry__search_issue_events, Read, Grep, Glob
---

# Sentry Investigation

対象: $ARGUMENTS (Sentry Issue URL)。

1. `mcp__sentry__get_issue_details(issueUrl='$ARGUMENTS')` でエラー種別・メッセージ・スタック・初回/最終発生・イベント数・ユーザー影響を取得する。無効URL・アクセス拒否はURLと組織を確認する。
2. 深い分析が必要な場合だけ `mcp__sentry__analyze_issue_with_seer(issueUrl='$ARGUMENTS')` を使う。
3. スタックのファイル・行・関数を読み、呼び出し経路と共通処理・類似箇所まで追う。Seerの提案もコードと照合する。
4. 概要・頻度・影響、根本原因、該当コードへのリンク、具体的な修正案を報告する。エラーの言い換えで済ませず、未確認の原因は仮説と区別する。
