---
name: orchestrate-epic
description: Orchestrate Epic issue as team leader. Delegate sub-issues to member agents in isolated worktrees. Members run in background and communicate via SendMessage.
disable-model-invocation: true
argument-hint: <epic-issue-url>
---

# Orchestrate Epic

チームリーダーとして行動し、サブ Issue をメンバーエージェントへ委譲する。メンバーは隔離された worktree で動作する。

> **NOTE**: Do NOT use Agent Teams (`team_name` / `TeamCreate`). Agent Teams + worktree isolation is a known incompatibility (anthropics/claude-code#33045). Instead, launch members as background agents with `isolation: "worktree"` and communicate via SendMessage by agent name.

## 引数

GitHub の Epic Issue URL (例: `https://github.com/owner/repo/issues/123`)

$ARGUMENTS

## 役割

### リーダー (= このメインセッション)
- Epic を読み、サブ Issue を洗い出す
- 依存関係を考慮してサブ Issue の優先度と実行順序を決める
- 実行モード (逐次または並列) をユーザーに選択してもらう
- メンバーエージェントを隔離された worktree で起動する
- 各メンバーのレポートをレビューし、成果物を承認する
- SendMessage でユーザーの指示をメンバーへ中継する
- コードは書かない
- ブランチは作成しない — 起動時点でアクティブなベースブランチに留まる

### メンバー (`member-<issue-number>`)
- `@.claude/agents/worktree-worker.md` で定義される
- `isolation: "worktree"` でバックグラウンド実行する
- worktree 内でのみ作業する
- 理解 → 実装 → レポート → 成果物提出のワークフローに従う
- SendMessage で進捗を報告する

## ワークフロー

### フェーズ 1: Epic の読み込みと計画

1. URL からオーナー、リポジトリ、Issue 番号を抽出する
2. Epic の詳細を取得する:
   ```bash
   gh issue view <number> --repo <owner>/<repo> --json number,title,body,state,url
   ```
3. サブ Issue を取得する:
   ```bash
   gh api repos/<owner>/<repo>/issues/<number>/sub_issues --paginate --jq '.[] | {number, title, state}'
   ```
4. API が失敗した場合は、Epic 本文の Issue 参照 (`#123`, `- [ ] #123`) をパースする
5. 各サブ Issue の詳細を取得する:
   ```bash
   gh issue view <sub-number> --repo <owner>/<repo> --json number,title,body,state,url
   ```
6. **オープン**なサブ Issue のみにフィルタする
7. 依存関係を分析し、実行順序を決定する
8. 順序付きサブ Issue 一覧を表示し、ユーザーに確認する:

> **実行モード:**
> - **Sequential** — メンバーを 1 つずつ起動し、各メンバーが承認されてから次を開始する (依存関係がある作業向け)
> - **Parallel** — 全メンバーを同時に起動し、それぞれ独立して作業する (独立した作業向け)
>
> モードを選択し、サブ Issue の順序を確認してください。

### フェーズ 2: 委譲

**メンバー起動パターン:**
```
Agent({
  name: "member-<issue-number>",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "Your assignment: Sub-issue #<number> in <owner>/<repo>.\nTitle: <title>\nURL: <url>\n\nDetails:\n<body>\n\nSend your report to: team-lead\n\nREMINDER: You are in an isolated worktree. NEVER checkout/switch branches in the main repo. Stay in your worktree directory. Run `pwd` before any git operation to confirm."
})
```

#### Sequential モード

各サブ Issue を順番に処理する:
1. **アナウンス**: `Starting member-<issue-number> on #<number>: <title>` と表示する
2. `run_in_background: true` で**メンバーを起動**する
3. **レポート受信時**: メンバーが SendMessage でレポートを送信する。リーダーがレビューする。
   - 修正が必要な場合: `SendMessage(to: "member-<issue-number>")` でフィードバックを中継する。メンバーが修正して再レポートする。
   - 承認する場合: メンバーに成果物の提出 (コミット & PR) へ進むよう伝える。
   - メンバーが失敗または応答しない場合: そのサブ Issue を失敗としてマークし、続行するかユーザーに確認する。
4. **PR 作成時**: PR URL を報告する。次のメンバーを起動する前にユーザーの承認を待つ。
5. **メンバーをシャットダウン**: `SendMessage(to: "member-<issue-number>", message: {type: "shutdown_request"})` を送る。

#### Parallel モード

1. `run_in_background: true` で**全メンバーを起動**する。
2. **モニタリング**: メンバーは完了次第 SendMessage でレポートを送信する。メッセージは自動配信される。
3. **各レポートが届き次第レビューする**:
   - 修正が必要な場合: SendMessage でフィードバックを中継する。
   - 承認する場合: メンバーに成果物の提出へ進むよう伝える。
4. 全メンバーが提出または失敗するまで続ける。

### メンバーとのやり取り

ユーザーはいつでも以下を依頼できる:
- **状況確認**: リーダーが `SendMessage(to: "member-<N>")` で進捗を問い合わせる
- **指示伝達**: リーダーが `SendMessage(to: "member-<N>")` で指示を中継する
- **スキップ**: 待たずに次のサブ Issue へ進む

### フェーズ 3: サマリーとクリーンアップ

全サブ Issue の処理が完了したら、以下を表示する:

```
## Epic Orchestration Summary

Epic: <url>
Mode: Sequential | Parallel

| Sub-issue | Title | Member | Status | Branch/PR |
|-----------|-------|--------|--------|-----------|
| #456      | ...   | member-456 | Done | PR #789 |
| #457      | ...   | member-457 | Done | PR #790 |
| #458      | ...   | member-458 | Failed | (error) |

Completed: <n>/<total>
```

その後、残っているメンバーに `SendMessage` で `message: {type: "shutdown_request"}` を送りシャットダウンする。
