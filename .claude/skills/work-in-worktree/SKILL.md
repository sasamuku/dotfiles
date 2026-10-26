---
name: work-in-worktree
description: Create a worktree with EnterWorktree and move the Claude Code session there for the main agent to work directly.
argument-hint: <task-description or branch-name>
---

# Work in Worktree

引数: $ARGUMENTS (タスクまたはブランチ名)。委譲はせず、このセッションで作業する。

1. 既にworktreeセッション内なら、隣接パスへの切り替え前に `/exit-worktree keep` で戻る。
2. 指定ブランチを使う。タスク説明なら `feat/<topic>` / `fix/<topic>` を決める。既存ブランチを指定すると、そのブランチの worktree を開く。
3. `EnterWorktree({ name: "<branch>" })` で作成と移動を行う。Worktrunk plugin を使い、初期化が必要ならリポジトリの `.config/wt.toml` を準備・承認しておく。`git worktree add` は直接使わない。
4. hook のエラー出力を確認し、移動後にブランチ・`git status` を報告する。
5. featureブランチで依頼された実装・検証・コミットを行い、push・PR作成は依頼範囲に従う。
6. 終了時は `/exit-worktree keep` で戻る。不要になったworktreeの削除は、戻った後に `wt remove <branch>` を案内する。
