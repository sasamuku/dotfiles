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
- **人手ブロッカー (requires-user-action)**: Terraform apply、本番デプロイ、認証情報の発行など、エージェントが安全に完了できない作業は、**コード部分を完了した時点**でレポート末尾に `## Requires user action` ブロックを立てて具体的な手順を列挙する。コードが未完了なのではなく「これ以上はユーザー作業」という状態は正規のゴールとして扱って良い。

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
7. 依存関係を分析し、**依存グラフを Phase 表で可視化する**。各 Phase には同時に起動可能な（依存が解決済みの）Issue のみを入れる:

   ```
   Phase 1 (並列可・独立):
     ├─ #N1  <title>
     └─ #N2  <title>

   Phase 2 (#N2 完了後・並列可):
     ├─ #N3  <title>
     └─ #N4  <title>

   Phase 3 (全完了後):
     └─ #N5  <title>
   ```

   各 Issue 行に「依存元 Issue 番号」を末尾に記載して根拠を明示する（例: `#N3  <title>  依存: #N2`）。
8. 順序付き Phase 表と依存関係を表示し、ユーザーに確認する:

> **実行モード:**
> - **Sequential** — メンバーを 1 つずつ起動し、各メンバーが承認されてから次を開始する (依存関係がきつく、1 件ずつレビューしたい場合向け)
> - **Parallel** — 全メンバーを同時に起動し、それぞれ独立して作業する (サブ Issue 間に依存が無い場合のみ。依存がある状態でこれを選ぶと [critical] 依存違反になるため、その場合は Phased Parallel を使うこと)
> - **Phased Parallel**（推奨: 依存がある中規模 Epic の既定） — Phase 表の各 Phase 内はメンバーを並列起動し、Phase 完了（= その Phase 内の全メンバーが PR 作成またはユーザー承認済み）を待って次 Phase を起動する
>
> モードを選択し、Phase 表の順序を確認してください。

### フェーズ 2: 委譲

**メンバー起動パターン:**
```
Agent({
  name: "member-<issue-number>",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "Your assignment: Sub-issue #<number> in <owner>/<repo>.\nTitle: <title>\nURL: <url>\n\nDetails:\n<body>\n\nSend your report to: team-lead\n\nREMINDER: You are in an isolated worktree. NEVER checkout/switch branches in the main repo. Stay in your worktree directory. Run `pwd` before any git operation to confirm.\n\nPR CREATION RULE: Before opening a PR, check for `.github/PULL_REQUEST_TEMPLATE.md` (and `.github/PULL_REQUEST_TEMPLATE/*.md`). If present, you MUST follow it verbatim: preserve every section heading (e.g. `## Issue`, `## なぜこの変更が必要か`, `## 動作確認`, `## その他`) in the same order, keep all HTML comments (review-tool instructions, prefix rules) intact, and only fill in the placeholder content inside each section. Do not invent new top-level sections or reorder them. If no template exists, use a concise body with a clear `## Summary` and `## Test plan`."
})
```

> **PR テンプレ準拠はメンバーの義務**。リーダーは起動プロンプトに上記 PR CREATION RULE が含まれていることを毎回確認する。メンバーが PR 作成後、リーダーは **必ず `gh pr view <N> --json body` で本文を検証**し、セクション見出し・HTML コメントの保持が不完全なら即 SendMessage で修正指示する（事後修正コストは起動時指示コストより高い）。

#### Sequential モード

各サブ Issue を順番に処理する:
1. **アナウンス**: `Starting member-<issue-number> on #<number>: <title>` と表示する
2. `run_in_background: true` で**メンバーを起動**する
3. **レポート受信時**: メンバーが SendMessage でレポートを送信する。リーダーがレビューする。
   - 修正が必要な場合: `SendMessage(to: "member-<issue-number>")` でフィードバックを中継する。メンバーが修正して再レポートする。
   - 承認する場合: メンバーに成果物の提出 (コミット & PR) へ進むよう伝える。
   - **レポートに `## Requires user action` ブロックが含まれる場合**: コード部分が達成条件を満たしていれば承認し、**PR 本文の「動作確認」または「その他」セクションに user action 項目を必ず含めるよう SendMessage で中継**する（例: `terraform apply はユーザー側で dev → staging → production の順に実施` など、メンバーが書いた手順そのままを PR に転記）。この場合そのサブ Issue は「Blocked on user」として扱い、ユーザー作業完了を Epic の前進条件に組み込む。
   - メンバーが失敗または応答しない場合: そのサブ Issue を失敗としてマークし、続行するかユーザーに確認する。
4. **PR 作成時**: PR URL を報告する。**リーダーは `gh pr view <N> --repo <owner>/<repo> --json body` で本文を取得し、`.github/PULL_REQUEST_TEMPLATE.md` のセクション見出し・HTML コメント保持を検証する**。逸脱があれば `gh pr edit <N> --body "$(cat <<'EOF' ... EOF)"` で即整形する（メンバーに戻すより速い）。整形後、次のメンバーを起動する前にユーザーの承認を待つ。
5. **メンバーをシャットダウン**: `SendMessage(to: "member-<issue-number>", message: {type: "shutdown_request"})` を送る。

#### Parallel モード

1. `run_in_background: true` で**全メンバーを起動**する。
2. **モニタリング**: メンバーは完了次第 SendMessage でレポートを送信する。メッセージは自動配信される。
3. **各レポートが届き次第レビューする**:
   - 修正が必要な場合: SendMessage でフィードバックを中継する。
   - 承認する場合: メンバーに成果物の提出へ進むよう伝える。
4. **PR 作成後の検証**: PR URL を受け取ったら **必ず `gh pr view <N> --repo <owner>/<repo> --json body` で本文を確認**し、`.github/PULL_REQUEST_TEMPLATE.md` のセクション見出し・HTML コメント保持を検証する。逸脱があれば `gh pr edit <N> --body "$(cat <<'EOF' ... EOF)"` で即整形する。
5. 全メンバーが提出または失敗するまで続ける。

#### Phased Parallel モード

依存関係のある中規模 Epic の既定モード。Phase 表（フェーズ 1 の手順 7）を実行単位とする:

1. **現在の Phase に属するメンバーのみ並列起動**する（`run_in_background: true`）。依存が未解決な次 Phase のメンバーは起動しない。
2. Parallel モード同様にレポート受信・レビュー・PR 検証・シャットダウンを進める。
3. **Phase 完了条件**: その Phase 内の全メンバーが PR 作成済み、またはユーザーが明示的にスキップを承認している状態。
4. **Phase 完了時**: サマリー表の該当 Phase 行をユーザーに提示し、次 Phase 起動の承認を取る（失敗した Issue があればここで取り扱いを確認する）。
5. ユーザー承認後、次 Phase の全メンバーを並列起動する。以降 1-4 を繰り返す。
6. 全 Phase 完了後、フェーズ 3（サマリー）へ進む。

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
| #457      | ...   | member-457 | Blocked on user (terraform apply) | PR #790 |
| #458      | ...   | member-458 | Failed | (error) |

Status は以下のいずれか:
- `Done` — PR 作成済み、エージェント側の作業完了
- `Blocked on user (<要約>)` — コード完了・PR 作成済みだが、PR 本文の user action セクションで示した作業（例: terraform apply、本番デプロイ）がユーザー側で未実施
- `Failed` — エージェントが達成条件を満たせなかった

Completed: <n>/<total> （`Done` + `Blocked on user` を達成扱いにカウント。`Failed` は含めない）
```

その後、残っているメンバーに `SendMessage` で `message: {type: "shutdown_request"}` を送りシャットダウンする。
