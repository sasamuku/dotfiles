---
name: enter-worktree
description: Move the Claude Code session into an existing worktree specified by branch or absolute path.
argument-hint: <branch-or-path>
---

# Enter Worktree

引数: $ARGUMENTS。`git worktree list` から登録済みの絶対パスを解決する。

- 絶対パス指定: 一覧への登録を確認する。
- ブランチ指定: チェックアウト先を探す。
- 未指定: 候補が1件なら使い、複数ならユーザーに選ばせる。
- 該当なし: 中断し、`wt add <branch>` または `/delegate-worker` を案内する。`git worktree add` は直接使わない。

```text
EnterWorktree({ path: "<absolute path>" })
```

`name` は新規作成になるため使わない。登録済みならリポジトリ隣接パスでも入れる。ただし既にworktreeセッション内の場合、切り替え先は `.claude/worktrees/` 配下に限られる。隣接パスへ移るには先に `/exit-worktree keep` で戻る。

移動後はブランチ・`git status` を報告する。復帰は [exit-worktree](../exit-worktree/SKILL.md) に従う。
