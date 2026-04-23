---
name: babysit
description: Autonomously triage PR review comments, apply necessary fixes, commit, push, and reply to comments. Designed for use with /loop 5m /babysit to continuously babysit PRs.
allowed-tools: Bash(git *), Bash(gh *), Read, Edit, Write
---

# PR の自動管理 (Babysit)

PR の自律的なメンテナンスループ。レビューコメントをトリアージし、必要に応じて修正を適用し、対応済みコメントへの返信を行う。ユーザー操作は不要で、完全自律で動作する。

## ワークフロー

### Step 1: 現在の PR を検出する

```bash
gh pr view --json number,headRepository,state -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name, state: .state}'
```

- 現在のブランチにオープンな PR がなければ、静かに終了する。
- state が `MERGED` または `CLOSED` であれば、`✅ PR is merged/closed. Stopping.` と出力して終了する。

### Step 2: 未解決のレビューコメントを取得する

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

スレッド内に既存の返信がない、未解決のコメントのみに絞り込む。

### Step 3: 各コメントを分類する

各コメントに優先度を割り当てる:

- 🔴 **Must** — バグ、セキュリティ問題、破壊的変更
- 🟡 **Investigate** — 変更が必要かどうか判断が必要なもの
- 🟢 **Info** — スタイル提案、細かい指摘

### Step 4: 自律的な意思決定

各コメントに対して、ユーザー入力なしで判断して対応する:

| Priority | Action |
|----------|--------|
| 🔴 Must | 修正する。ファイルを読み込み、変更を適用する。 |
| 🟡 Investigate | 明らかに正しく低リスクなら修正する。曖昧またはリスクがあればスキップする。 |
| 🟢 Info | 些細で安全な場合 (例: 未使用 import の削除) を除いてスキップする。 |

**修正しない**条件:
- プロダクトやデザインに関する意思決定が必要な変更
- 他の挙動を壊す可能性がある修正
- コメントの意図が不明瞭な場合

### Step 5: コミットとプッシュ (修正を適用した場合のみ)

`-y` オプションを付けて @.claude/skills/commit/SKILL.md を実行し、その後 @.claude/skills/push/SKILL.md を実行する。

### Step 6: 返信前にプッシュを確認する

コミットハッシュを参照する返信を投稿する前に、コミットがプッシュ済みであることを確認する:

```bash
git log origin/$(git branch --show-current)..HEAD --oneline
```

コミットがまだプッシュされていなければ、先に @.claude/skills/push/SKILL.md を実行する。

### Step 7: 各コメントに返信する

処理したすべてのコメントに対して、自律的に返信を投稿する:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -X POST -f body="{reply}"
```

返信テンプレート:

| Situation | Reply |
|-----------|-------|
| Fixed | `Fixed in {commit_hash}.` |
| Won't fix — ambiguous | `Skipping for now — intent is unclear. Please clarify if action is needed.` |
| Won't fix — risky | `Keeping current approach to avoid unintended side effects.` |
| Investigated, no change needed | `Investigated — current implementation handles this correctly.` |
| Info, skipped | `Noted.` |

### Step 8: レポート

```
✅ Fixed #1, #3 — committed and pushed (abc1234)
⏭️  Skipped #2 (ambiguous), #4 (risky)
💬 Replied to #1, #2, #3, #4
```

対応すべきコメントがない場合: `✅ No actionable comments found.`
