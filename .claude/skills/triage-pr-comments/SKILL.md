---
name: triage-pr-comments
description: Triage PR review comments with priority categorization (must/investigate/info). Use when handling AI reviewer feedback (CodeRabbit, Copilot, etc.) or managing PR comments systematically.
disable-model-invocation: true
allowed-tools: Bash(gh *)
---

# PR Review Comments Manager

AI レビュアー (CodeRabbit、Copilot など) および人間レビュアーからの PR レビューコメントを管理する、2 フェーズのワークフロー。

## 引数

PR 番号または URL (省略時は現在のブランチの PR を使用)

$ARGUMENTS

---

## フェーズ 1: 分析とカテゴリ分け

### ステップ 1: PR 情報を取得する

```bash
gh pr view --json number,headRepository -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name}'
```

### ステップ 2: 全レビューコメントを取得する

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments
```

### ステップ 3: カテゴリ分けして提示する

各コメントに以下を付与する:
- **ID**: 連番 (例: #1, #2, #3)
- **優先度**:
  - 🔴 **Must** - バグ、セキュリティ問題、破壊的変更 — 修正必須
  - 🟡 **Investigate** - 検討が必要、変更が必要かどうか要判断
  - 🟢 **Info** - 情報提供、スタイル提案、軽微な指摘

### 出力フォーマット

ユーザーへの提示はテーブル形式で行う:

```
## PR Review Comments Summary

| ID | Priority | File | Summary |
|----|----------|------|---------|
| #1 | 🔴 Must | src/auth.ts:42 | Null check missing before accessing user.id |
| #2 | 🟡 Investigate | src/api.ts:15 | Consider using async/await instead of .then() |
| #3 | 🟢 Info | src/utils.ts:8 | Unused import statement |
...

### Details

**#1** 🔴 Must - src/auth.ts:42
> Original comment text here...
Intent: Prevent potential runtime error when user object is undefined

**#2** 🟡 Investigate - src/api.ts:15
> Original comment text here...
Intent: Code style suggestion for better readability

...
```

提示後、ユーザーが問題に対応するのを待つ。

---

## フェーズ 2: 対応済みコメントへの返信

ユーザーが「コメントに返信して」などと指示した場合:

### ステップ 1: 対応済みコメントを特定する

どのコメント ID が対応済みかユーザーに確認するか、コンテキスト内の最近のコミット/変更から検出する。

### ステップ 2: 対応済みコメントにのみ返信する

対応済みの各コメントにスレッド返信を投稿する:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST \
  -f body="Reply content" \
  -F in_reply_to={comment_id}
```

### 返信ガイドライン

- **実際に対応したコメントにのみ返信する**
- 修正を行った場合はコミットハッシュを参照する (例: "Fixed in abc123")
  - **コミットハッシュを含む返信を投稿する前に、GitHub 上でリンクが解決されるよう、コミットがリモートにプッシュ済みであることを確認する** (`git push` が必要な場合は実行する)
- 「対応しない」と判断した場合は理由を説明する
- 調査中のコメントはスキップする
- 返信は簡潔に保つ

### 返信例

| Situation | Reply |
|-----------|-------|
| Fixed | "Fixed in abc123. Added null check as suggested." |
| Won't fix | "Keeping current approach because X." |
| Investigated, no change needed | "Investigated - current implementation handles this case via Y." |
