---
name: exit-worktree
description: Exit the current worktree session and return to the original working directory. Use when the user wants to leave a worktree entered via /enter-worktree or /delegate-worker — trigger on phrases like "exit the worktree", "worktree から出て", "元のディレクトリに戻って".
argument-hint: [keep|remove]
---

# worktree からの離脱

`EnterWorktree` で入った worktree セッションを終了し、元のディレクトリに戻る。

## 引数

$ARGUMENTS

## ワークフロー

### 1. action を決める

- 引数なし → `"keep"` (デフォルト)
- `keep` → worktree とブランチをディスクに残す
- `remove` → worktree とブランチを削除する

### 2. 終了する

```
ExitWorktree({ action: "keep" })  // または "remove"
```

注意事項:

- **`path` で入った worktree (= `/delegate-worker` や `/enter-worktree` 経由) は `"remove"` では削除されない**。`"keep"` で元のディレクトリに戻るのが正しい。削除したい場合は、戻ったあとに `wt remove <branch>` を案内する (worktree がワーカー所有なら先にワーカーをシャットダウンする)
- `"remove"` 指定時に未コミット変更や未マージコミットがあるとツールがエラーで一覧を返す。その場合は**ユーザーに確認してから** `discard_changes: true` で再実行する。無断で破棄しない
- worktree セッションがアクティブでない場合は no-op となる。その旨を報告して終了する

### 3. 終了後

- 戻り先のディレクトリと、worktree を残した場合はそのパス・ブランチ名を報告する
