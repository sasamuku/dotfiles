---
name: work-in-worktree
description: Create a worktree with EnterWorktree and move the Claude Code session there for the main agent to work directly.
argument-hint: <task-description or branch-name>
---

# Work in Worktree

引数: $ARGUMENTS (タスクまたはブランチ名)。委譲はせず、このセッションで作業する。

1. 既にworktreeセッション内なら、隣接パスへの切り替え前に `/exit-worktree keep` で戻る。
2. 指定ブランチを使う。タスク説明なら `feat/<topic>` / `fix/<topic>` を決める。`git show-ref --verify --quiet refs/heads/<branch>` で既存なら中断し、別名か既存worktreeへの移動かを確認する。
3. `EnterWorktree({ name: "<branch>" })` で作成と移動を同時に行う。`WorktreeCreate` hook (`~/.claude/hooks/hook_worktree_create.sh`) がリポジトリ隣接パス `<parent>/<repo>-<branch>` に worktree を作り、`.wt_hook.sh` を発火させる。`git worktree add` や `wt add` + `EnterWorktree({ path })` は使わない (`.claude/worktrees/` 外への `path` 指定は auto mode でも必ず許可プロンプトが出る)。
4. hook のエラー出力を確認し、移動後にブランチ・`git status` を報告する。
5. featureブランチで依頼された実装・検証・コミットを行い、push・PR作成は依頼範囲に従う。
6. 終了時は `/exit-worktree keep` で戻る。不要になったworktreeの削除は、戻った後に `wt remove <branch>` / `wt clean` を案内する。
