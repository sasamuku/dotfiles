---
name: delegate-worker
description: Delegate implementation or investigation to a worktree-worker in an isolated git worktree.
argument-hint: <task-description>
disable-model-invocation: true
---

# Delegate Worker

引数: $ARGUMENTS (委譲する作業)。タスク・担当範囲・関連ファイル・エラー・再現手順をプロンプトに含める。Issue指定があれば `gh issue view` でタイトル・本文・URLを取得する。
調査のみなら `report only, do not implement or commit` を明示する。

## 起動・追随 (Claude Code)

```text
Agent({
  name: "worker",
  subagent_type: "worktree-worker",
  isolation: "worktree",
  run_in_background: true,
  prompt: "<task/context>\nIn your first report, include the absolute path of your worktree.\nSend your report to: main"
})
```

`main` はgitブランチではなく親セッション名。複数workerがいれば名前を区別し、以降の宛先にも使う。進捗・完了は通知で受け取り、ポーリングしない。

最初の報告でパスを受け取ったら [enter-worktree](../../../.claude/skills/enter-worktree/SKILL.md) に従い既存worktreeへ移動する。調査のみでコードの確認が不要なら省略できる。パスやブランチ名を推測して新規作成しない。

## 起動・追随 (Codex)

Codex には起動時に worktree を作る機能が無いので、親が作ってから任せる。

1. `wt switch --create <branch> --no-cd --format json` で worktree を作り、出力の `path` を受け取る。初期化の hook の承認を求められたら、内容を確かめてから承認する (`--yes` で飛ばさない)。作れなければ、別の clone や別の場所で代わりを作らず、エラーを添えて止まり、報告する。
2. `spawn_agent` を `agent_type: "worktree-worker"` で呼び、`message` にタスクと `Worktree: <path>` を書く。
3. 進捗と報告は `wait_agent` で受け取る。動いている worker には `send_message`、返答を終えた worker には `followup_task` で指示を送る。
4. 親は worktree へ移動せず、`git -C <path>` と絶対パスで読む。下の enter-worktree と exit-worktree は使わない。
5. 終了させる道具は無い。最終成果物が届いたら指示を送るのをやめ、動いていれば `interrupt_agent` で止める。

## 報告・提出

- 報告を確認し、必要な修正を `SendMessage` (Codex は `send_message` か `followup_task`) で伝える。
- 実装を承認したらコミット・pushへ進める。PRが依頼されている場合やIssueが割り当てられている場合はPRも作成させ、割り当てIssueがあればcloseするPRにする。調査のみなら報告で終了する。
- 最終成果物 (PR・push・調査報告) が届いたら `SendMessage` の `shutdown_request` でworkerを終了する。マージなど下流のイベントを待たない。
- worktreeへ移動していた場合は [exit-worktree](../../../.claude/skills/exit-worktree/SKILL.md) の `keep` で元へ戻る。workerのworktree・ブランチは削除しない。
