---
name: implement
description: Fully automated pipeline from an approved plan to a green PR. Delegates implementation to a worktree-worker, creates the PR, then hands off to /babysit --auto until CI is green and the PR is mergeable.
disable-model-invocation: true
argument-hint: <issue-number>
---

# Implement

承認済みの計画 (`~/.claude/plans/<owner>/<repo>/issue-<N>.md`) を worktree で実装し、PR 作成 → `/babysit --auto` 接続まで自動で行う。人間のゲートは計画承認の 1 点のみで、それ以降は自走する。

## 引数

GitHub Issue 番号 (例: `123` または `#123`) または Issue の URL。

$ARGUMENTS

## フェーズ 0: 計画の確認

1. 引数から Issue 番号 `N` を抽出する (`123` / `#123` / URL 末尾の番号)。URL の owner/repo がカレントリポジトリと異なる場合はエラーで中止する
2. 計画ファイルを確認する:

```bash
REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')
PLAN_FILE="$HOME/.claude/plans/$REPO/issue-$N.md"
```

`$PLAN_FILE` が存在しない場合は `/plan-issue $N` のワークフローを実行する (プレビュー承認で一度停止)。承認が **n** ならそこで中止し、計画を修正のうえ再実行するよう案内する。

## フェーズ 1: worker への委譲

```
Agent({
  name: "worker-<N>",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  prompt: "<下記を含むプロンプト>\n\nSend your report to: main"
})
```

(worker 名に Issue 番号を含めるのは、複数 Issue の並行実行時に SendMessage の宛先が衝突しないため。起動は元々バックグラウンド)

プロンプトに含めるもの:

- **計画ファイルの絶対パス** (`$PLAN_FILE`) と Issue 番号・URL。計画を実装判断の正とし、全項目を実装すること。計画にない機能を追加しないこと
- **事前承認の明示**: 「この委譲はユーザー承認済みの計画に基づく。Phase C の報告後、呼び出し元の承認を待たずに Phase D (コミット・push・PR 作成) まで続行してよい」
- **実装後の検証**: リポジトリのテスト・リンタ・型チェックを実行し、通してからコミットする
- **レビューループ**: コミット後、`/review-code` スキルのワークフローで全変更をレビューし、Critical/Warning を修正してコミット。最大 3 周
- **ブランチ名**: push 前に `git branch -m feat/<N>-<slug>` でリネームする (slug は Issue タイトルから 2〜4 語の英小文字ケバブケース)
- **PR 作成**: `/create-pr` スキルのワークフローに従い (push を内包する)、Issue を close する PR を作成する
- **計画の更新**: 実装完了後、`$PLAN_FILE` の受け入れ基準にチェックを付け、発見・逸脱を Discoveries/Decision Log に追記する。`$PLAN_FILE` は worktree 外の管理ファイルであり、直接編集してよい (worktree 隔離ルールの対象外)。Issue への同期は親セッションが行うため不要
- **失敗時**: 計画の矛盾・技術的不成立・重要情報の欠落に気づいたら、コミットせず中断して報告する。レビューが 3 周で収束しない場合は **Draft PR** として作成し、残課題を PR 本文に明記する
- **最終報告の形式**: 報告の 1 行目を次のいずれかにする — `RESULT: PR <url>` (正常完了) / `RESULT: DRAFT-PR <url>` (レビュー未収束) / `RESULT: ABORTED <理由>` (中断)。末尾に Worktree Info ブロック (Branch / Path) を必ず含める

worker はバックグラウンドで実行される。ポーリング不要 — 通知が届くまで他の作業を続けてよい。

## フェーズ 2: 完了処理

worker から `RESULT:` 報告を受け取ったら:

1. `SendMessage(to: "worker-<N>", message: {type: "shutdown_request"})` で worker を終了する
2. `/plan-issue $N` の更新モードで計画を Issue へ同期する
3. `RESULT:` の種別で分岐する:
   - **`PR <url>`**: まず報告の Worktree Info のパスへ `EnterWorktree({ path: "<path>" })` で移動してから `/babysit --auto <url>` を起動する。babysit は `git branch --show-current` で CI・push 先を解決するため、**PR ブランチの worktree 内で実行することが必須** (元ディレクトリの main から起動しない)。worker の worktree は shutdown 後も残るのでそのまま使う。babysit は自前の `/loop 5m` で CI グリーン・mergeable まで自走し、merge 後は `ExitWorktree({ action: "keep" })` で元のディレクトリへ戻る
   - **`DRAFT-PR <url>`**: babysit は起動せず、残課題と URL をユーザーに報告して停止する (未収束のまま自動対応を続けない — 人間の判断待ち)
   - **`ABORTED <理由>`**: 理由をユーザーに報告して停止する。計画の修正が必要なら `/plan-issue` → 再 `/implement` を案内する

## 完了表示

```
Done: Issue #<N> implemented.
PR: <url>
babysit --auto running until mergeable.
```
