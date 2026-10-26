---
name: exit-worktree
description: Return the Claude Code session from a worktree, keeping it by default or removing it when requested.
argument-hint: [keep|remove]
---

# Exit Worktree

引数: $ARGUMENTS。既定は `keep` (worktree・ブランチを保持)。`remove` は削除指定。

```text
ExitWorktree({ action: "keep" })  // 削除指定なら "remove"
```

- `path` で入ったworktreeは `remove` でも削除されない。`keep` で戻り、削除が必要なら `wt remove <branch>` を案内する。worker所有なら先にworkerを終了させる。
- `Could not verify worktree state` で削除が拒否された場合は `keep` で戻り、元のリポジトリから `wt remove --foreground <worktreeの絶対パス>` を使う。状態確認を飛ばすための強制削除はしない。
- 削除は Worktrunk plugin に任せる。失敗時は理由を報告し、強制削除はユーザーの破棄承認後だけ行う。worktree とブランチの削除結果は別々に確認する。
- worktreeセッション外ならno-opと報告して終了する。

復帰先を報告し、保持した場合はworktreeのパス・ブランチも示す。
