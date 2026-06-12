---
name: enter-worktree
description: Switch the current session into an existing git worktree (e.g. one created by /delegate-worker or `wt add`). Use when the user wants to enter, cd into, or follow a worktree — trigger on phrases like "enter the worktree", "worktree に入って", "ワーカーの worktree に移動して".
argument-hint: <branch-or-path>
---

# 既存 worktree への移動

セッションのカレントディレクトリを既存の worktree へ切り替える。`/delegate-worker` のワーカーが作った worktree や `wt add` で作った worktree に追随するために使う。

## 引数

$ARGUMENTS

## ワークフロー

### 1. worktree のパスを解決する

```bash
git worktree list
```

- 引数が**絶対パス**ならそのまま使う (一覧に存在することを確認する)
- 引数が**ブランチ名**なら、一覧から該当ブランチがチェックアウトされている worktree のパスを探す
- 引数が**ない**場合: 一覧を表示し、候補が 1 つならそれを使う。複数あれば AskUserQuestion でユーザーに選ばせる
- 該当する worktree がない場合は中断し、`/delegate-worker` または `wt add <branch>` での作成を案内する (`git worktree add` は直接使わない)

### 2. セッションを切り替える

```
EnterWorktree({ path: "<resolved absolute path>" })
```

- `name` ではなく必ず `path` を渡す。`name` は新規作成になってしまう
- `path` は `git worktree list` に登録済みであれば、リポジトリ隣接ディレクトリ (例: `<project>-<branch>`) でも入れる
- ただし**すでに worktree セッション内にいる場合**、隣接パスへの切り替えはできない (`path` 切り替えは `.claude/worktrees/` 配下のみ)。先に `/exit-worktree` で戻ってから入り直す

### 3. 移動後

- 現在のブランチと `git status` を簡潔に報告する
- 元のディレクトリに戻るには `/exit-worktree` を使う
