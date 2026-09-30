---
name: work-in-worktree
description: Create a worktree with wt add and move the Claude Code session there for the main agent to work directly.
argument-hint: <task-description or branch-name>
---

# Work in Worktree

引数: $ARGUMENTS (タスクまたはブランチ名)。委譲はせず、このセッションで作業する。

1. 既にworktreeセッション内なら、隣接パスへの切り替え前に `/exit-worktree keep` で戻る。
2. 指定ブランチを使う。タスク説明なら `feat/<topic>` / `fix/<topic>` を決める。`git show-ref --verify --quiet refs/heads/<branch>` で既存なら中断し、別名か既存worktreeへの移動かを確認する。
3. `.wt_hook.sh` を発火させるため、`git worktree add` を直接使わず以下を実行する。

```bash
zsh -c 'source ~/.config/zsh/functions/wt.zsh && wt add "<branch>"'
```

出力の `Created worktree at: <path>` から絶対パスを取得し、フックのエラーを確認する。

4. [enter-worktree](../enter-worktree/SKILL.md) に従い作成先へ移動する。`name` による別worktreeの新規作成を避ける。
5. featureブランチで依頼された実装・検証・コミットを行い、push・PR作成は依頼範囲に従う。
6. 終了時は `/exit-worktree keep` で戻る。不要になったworktreeの削除は、戻った後に `wt remove <branch>` / `wt clean` を案内する。
