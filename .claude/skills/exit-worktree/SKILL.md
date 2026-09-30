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
- `remove` が未コミット変更・未マージコミットで失敗した場合、一覧を示し、**ユーザーの破棄承認後だけ** `discard_changes: true` で再実行する。
- worktreeセッション外ならno-opと報告して終了する。

復帰先を報告し、保持した場合はworktreeのパス・ブランチも示す。
