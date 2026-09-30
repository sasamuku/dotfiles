---
name: orchestrate-epic
description: Coordinate an Epic's sub-issues through worktree workers, respecting dependencies and reporting progress, PRs, and user-action blockers.
disable-model-invocation: true
argument-hint: <epic-issue-url>
---

# Orchestrate Epic

対象: $ARGUMENTS

リーダーは計画・委譲・成果物レビューを担当し、コードを書かず元のブランチに留まる。メンバーは [worktree-worker](../../agents/worktree-worker.md) に従い、隔離された worktree 内だけで作業する。

## 計画

1. Epic とサブ Issue の本文・状態を取得し、未完了の Issue を対象にする。公式紐づけを優先し、取得できなければ Epic 本文のタスクリストで補完する。
2. 依存元を添えた Phase 表を提示し、実行モードと順序の承認を得る。
   - Sequential: 1件ずつ承認後に次へ。
   - Parallel: 全件が独立している場合だけ同時実行。
   - Phased Parallel: 依存解消済みの Phase 内を並列実行。次 Phase の開始はユーザー承認後。
3. `TaskCreate` で Issue ごとのタスク・依存を登録し、開始・修正中・PR作成・失敗を `TaskUpdate` で反映する。

## 委譲と共通処理

Agent Teams ではなく、名前付きバックグラウンド Agent と SendMessage を使う。

```text
Agent({
  name: "member-<issue-number>",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "<Issue番号・URL・本文・依存成果物・下記の制約>\nSend your report to: main"
})
```

各メンバーに渡す制約:

- worktree 内でだけ変更し、メイン側のブランチを切り替えない。
- 実装・検証を報告し、リーダーの承認後にコミット・push・PR作成へ進む。
- PR は対象リポジトリのテンプレートに従い、見出し・順序・bot制御コメントを保持する。
- 最終報告に `Worktree Info` (branch、絶対パス、`wt <branch>`) を含める。
- 本番デプロイ・認証情報の発行等、人が行う作業はコードを完成させてから `Requires user action` に具体的手順を書く。PR本文にも反映する。
- 完了後も自己終了せず、追加指示を受けられる状態で保持する。

レポートを受けたら達成条件・検証結果を確認し、修正指示または成果物提出の承認を返す。PR作成後は `gh pr view <N> --repo <owner>/<repo> --json body` でテンプレートと user action 項目を確認し、不足があればメンバーに直させる。

## 依存・終了の扱い

- 下流を始める前に依存成果物が利用可能か確認する。PRを作っただけで依存解消とみなさない。
- 人手の作業が残る Issue は `Blocked on user` とし、その作業に依存する次 Phase を進めない。
- 失敗・無応答は完了扱いにせず、続行方法をユーザーに確認する。
- 完了したメンバーも追加指示用に保持する。PRマージ/クローズ後、ユーザーが終了を依頼した時点で `shutdown_request` を送る。

## 報告

`Issue / 状態 / branch・worktree / PR / 残る人手作業` の表で示す。`Done`、`Blocked on user`、`Failed` を区別し、人手待ちを完了数に含めない。
ユーザーは `wt <branch>` で手元から作業でき、メンバーへの追加依頼はリーダーが SendMessage で中継する。
