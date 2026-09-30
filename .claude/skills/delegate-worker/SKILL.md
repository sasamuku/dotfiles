---
name: delegate-worker
description: Delegate implementation or investigation to a worktree-worker in an isolated git worktree.
argument-hint: <task-description>
---

# Delegate Worker

引数: $ARGUMENTS (委譲する作業)。タスク・担当範囲・関連ファイル・エラー・再現手順をプロンプトに含める。Issue指定があれば `gh issue view` でタイトル・本文・URLを取得する。
調査のみなら `report only, do not implement or commit` を明示する。

## 起動・追随

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

最初の報告でパスを受け取ったら [enter-worktree](../enter-worktree/SKILL.md) に従い既存worktreeへ移動する。調査のみでコードの確認が不要なら省略できる。パスやブランチ名を推測して新規作成しない。

## 報告・提出

- 報告を確認し、必要な修正を `SendMessage` で伝える。
- 実装を承認したらコミット・pushへ進める。PRが依頼されている場合やIssueが割り当てられている場合はPRも作成させ、割り当てIssueがあればcloseするPRにする。調査のみなら報告で終了する。
- 最終成果物 (PR・push・調査報告) が届いたら `SendMessage` の `shutdown_request` でworkerを終了する。マージなど下流のイベントを待たない。
- worktreeへ移動していた場合は [exit-worktree](../exit-worktree/SKILL.md) の `keep` で元へ戻る。workerのworktree・ブランチは削除しない。
