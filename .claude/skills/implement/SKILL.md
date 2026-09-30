---
name: implement
description: Implement an approved issue plan in a worktree, create a PR, and run babysit --auto until CI is green and the PR is mergeable.
disable-model-invocation: true
argument-hint: <issue-number>
---

# Implement

引数: $ARGUMENTS (Issue番号・URL)。URLのowner/repoが現在のリポジトリと異なれば中止する。

## 計画の確認

[plan-issue](../plan-issue/SKILL.md) の規約に従い、`~/.claude/plans/<owner>/<repo>/issue-<N>.md` を作業コピー、Issueの `PLANS_SYNC_MARKER` コメントを正本とする。

- ローカルファイルがあっても同期コメントと照合する。一致すれば既存の承認を引き継ぐ。ローカルがなければ正本を取り込む。
- 差分があれば会話での承認内容・更新時刻を確認し、未同期の変更を捨てずに整合させる。どちらが承認済みか判別できなければ確認する。ファイルの存在だけで承認済みと扱わない。
- 計画がなければ `/plan-issue <N>` で作成し、承認後に続行する。却下なら停止する。

## 委譲

`worktree-worker` を `name: worker-<N>`、`isolation: worktree`、`run_in_background: true` で起動する。通知で報告を受け、ポーリングしない。プロンプトに以下を含める:

- Issue番号・URLと整合済み計画の絶対パス。計画の全項目を実装し、範囲外の機能は追加しない。
- 事前承認: Phase Cの報告後、追加承認を待たずPhase D (コミット・push・PR作成) へ進む。
- リポジトリのテスト・lint・型チェックを通してコミットし、[review-code](../review-code/SKILL.md) で全変更をレビューする。Critical/Warningの修正・検証・コミットは最大3周。
- push前に `git branch -m feat/<N>-<slug>` で改名する。slugはIssueタイトルから英小文字ケバブケース2〜4語。
- [create-pr](../create-pr/SKILL.md) に従い、IssueをcloseするPRを作成する。レビューが3周で収束しなければDraftを維持し、残課題を本文へ記載する。
- 計画の矛盾・技術的不成立・重要情報の欠落が判明したら、作業を中断し、以後のコミット・push・PR作成に進まず報告する。
- 完了時に作業コピーの受け入れ基準・Discoveries・Decision Logを更新する。この計画ファイルのみworktree外の編集を許可する。Issueへの同期は親が行う。
- 報告先は親セッション (`Send your report to: main`、gitブランチ名ではない)。最終報告の先頭は `RESULT: PR <url>` (正常完了) / `RESULT: DRAFT-PR <url>` (レビュー未収束) / `RESULT: ABORTED <理由>` (中断)、末尾はWorktree Info (Branch / 絶対Path)。

## 完了処理

最終報告を受けたら `SendMessage` の `shutdown_request` でworkerを終了し、`/plan-issue <N>` の更新モードで計画をIssueへ同期する。

- `PR`: 報告されたworktreeへ [enter-worktree](../enter-worktree/SKILL.md) で入り、そこで `/babysit --auto <url>` を実行する。元ディレクトリから修正・pushしない。
- `DRAFT-PR` / `ABORTED`: babysitを起動せず、URL・残課題または中断理由を報告して停止する。

[babysit](../babysit/SKILL.md) の停止条件に従い、mergeable・PR終了・進行不能などで監視が終了したら、入ったworktreeから `/exit-worktree keep` で戻る。ループ稼働中はPR側に留まり、マージ自体は待たない。単発実行しかできなければ継続監視なしと報告して戻る。

PRの状態・監視の稼働/停止・未解決事項を実態どおり報告する。監視開始を完了扱いしない。
