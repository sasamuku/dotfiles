---
name: delegate-worker
description: Delegate a task to a worktree-worker agent running in an isolated git worktree. Use this skill when you want a sub-agent to implement code changes, fix bugs, or investigate errors in a separate worktree — keeping the main session clean. Trigger on phrases like "delegate this to a worker", "fix this in a worktree", "have a worker handle this", or when the user wants code changes done in isolation.
argument-hint: <task-description>
---

# ワーカーへのタスク委譲

隔離された git worktree 内で `worktree-worker` エージェントを起動し、バックグラウンドでタスクを処理させる。

## 引数

$ARGUMENTS

## ワークフロー

### 1. プロンプトを準備する

引数からワーカー用のプロンプトを組み立てる。以下を含める:

- **タスクの説明**: ワーカーが行うべき内容
- **タスクの種別**: 調査・分析のみ (コード変更なし) の場合、ワーカーが実装に踏み込まないよう、「report only, do not implement or commit」とプロンプトに明記する
- **Issue のコンテキスト** (Issue URL が提供された場合): `gh issue view` でタイトル・本文・URL を取得し、ワーカーが Issue をクローズする PR を作成できるよう含める
- **関連コンテキスト**: ユーザーが言及したファイルパス、エラーメッセージ、再現手順

### 2. ワーカーを起動する

```
Agent({
  name: "worker",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "<prepared prompt>\n\nIn your first report, include the absolute path of your worktree so the parent session can cd into it.\n\nSend your report to: main"
})
```

`Send your report to: main` — ここでの `main` は git ブランチではなく、**親セッション名** (トップレベルの Claude Code セッションのデフォルト名) を指す。ワーカーは SendMessage を呼ぶ際にこれを `to` フィールドとして使用する。

### 3. ワーカーの worktree に追随する

ワーカーが worktree のパスを報告したら、ユーザーがリアルタイムで変更を確認できるよう、親セッションをそこへ移動する:

```
EnterWorktree({ path: "<worker's worktree absolute path>" })
```

注意事項:
- `name` ではなく `path` を渡すこと。これにより既存の worktree に入る (新規作成ではない)。
- ワーカーのブランチがそこにチェックアウトされているため、ユーザーはすぐに変更後のコードを確認できる。
- 後で元のディレクトリに戻るには: `ExitWorktree({ action: "keep" })`。worktree はワーカーが所有しているため `"keep"` を使うこと (`"remove"` は不可)。

### 4. コミュニケーション

- ワーカーは SendMessage で進捗を報告する。各レポートが届いたら確認する。
- 修正が必要であれば `SendMessage(to: "worker")` でフィードバックを伝える。
- 承認したら、ワーカーに成果物の提出 (コミット & プッシュ、または Issue が割り当てられていれば PR) に進むよう指示する。
- ワーカーが完了を報告したら (最終レポート — 例: 「PR opened at ...」「commit pushed」、または調査タスクであれば「report ready」)、`SendMessage(to: "worker", message: {type: "shutdown_request"})` を送り、`ExitWorktree({ action: "keep" })` でセッションを元のディレクトリに戻す。PR のマージなど下流のイベントを待たず、ワーカーの成果物が出た時点でシャットダウンする。
