---
name: work-in-worktree
description: Create a new git worktree via `wt add` (firing .wt_hook.sh) and move the current session into it so the MAIN agent works there directly — no sub-agent. Use when the session started on main/master and the user wants to do the task themselves in an isolated worktree. Trigger on phrases like "worktree を作ってそこで作業して", "このセッションで worktree に入って直接やって", "work in a worktree yourself". For delegating to a background sub-agent instead, use /delegate-worker.
argument-hint: <task-description or branch-name>
---

# メインセッションで worktree 作業

worktree を新規作成してセッションごと移動し、**メインエージェント自身**がそこでタスクを実施する。サブエージェントは起動しない。コード変更は worktree に隔離されるため、main ブランチを汚さない。

## 引数

$ARGUMENTS

## 前提

すでに worktree セッション内 (EnterWorktree 済み) の場合、リポジトリ隣接パスへの切り替えはできない (`path` 切り替えは `.claude/worktrees/` 配下のみ)。先に `/exit-worktree` で元のディレクトリに戻ってから実行する。

## ワークフロー

### 1. ブランチ名を決める

- 引数がブランチ名形式 (`feat/...` 等) ならそれを使う。タスク説明なら内容から `feat/<topic>` / `fix/<topic>` で簡潔に命名する
- `git show-ref --verify --quiet refs/heads/<branch>` が成功する (= 既存ブランチ) 場合は中断し、別名にするか `/enter-worktree` で既存 worktree に入るかをユーザーに確認する

### 2. worktree を作成する

`git worktree add` は使わず、`.wt_hook.sh` を発火させるため `wt add` を経由する:

```bash
zsh -c 'source ~/.config/zsh/functions/wt.zsh && wt add "<branch>"'
```

- worktree はリポジトリ隣接の `<parent>/<project>-<safe-branch>` に作られる (`/` は `-` に変換)
- 出力の `Created worktree at: <path>` から絶対パスを取得し、フック出力 (依存インストール等) にエラーがないか確認する

### 3. セッションを移動する

```
EnterWorktree({ path: "<created worktree absolute path>" })
```

`name` ではなく `path` を渡す (`name` は `.claude/worktrees/` 配下に別 worktree を新規作成してしまい、`.wt_hook.sh` が発火しない)。

### 4. タスクを実施する

フィーチャーブランチ上なのでブランチ安全性ルールの確認は不要。コード変更・テスト・コミットを進め、指示に応じてプッシュ・PR 作成まで行う。

### 5. 終了時

`/exit-worktree` (keep) で元のディレクトリに戻る。worktree とブランチが不要になったら (PR マージ後など)、戻ったあとに `wt remove <branch>` または `wt clean` を案内する。
