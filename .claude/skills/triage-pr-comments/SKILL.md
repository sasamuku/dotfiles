---
name: triage-pr-comments
description: Triage and reply to PR review comments. Phase 1 categorizes comments by priority (must/investigate/info); Phase 2 posts threaded replies for resolved comments. Use when handling AI reviewer feedback (CodeRabbit, Copilot, etc.) or managing PR comments systematically.
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

`--paginate` を必ず付ける（付けないとデフォルト 30 件で打ち切られ、大きな PR で取りこぼす）。

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

### ステップ 3: カテゴリ分けして提示する

まず返信スレッドを再構成する:

- `in_reply_to_id` が **ある**コメントは「返信」として、**親コメントの下にぶら下げる**。独立エントリとして連番 ID を付けない。
- 返信に `✅ Resolved` / `✅ Addressed` / "Fixed in xxx" 等の解決宣言が含まれていれば、**親コメントの Summary 列末尾に `✅ Resolved` を付記**し、優先度はそのまま残す（格下げしない）。
- AI bot が自分の元コメントに後から `✅ Addressed in commits xxx..yyy` のように追記するケース（`in_reply_to` なし）も同様に `✅ Resolved` 扱い。

次に独立エントリ（`in_reply_to_id` が null）に連番を付ける:

- **ID**: 連番 (例: #1, #2, #3)
- **Reviewer**: `gh api` レスポンスの `user.login` と `user.type` から下記マッピング表で判定。
  - `user.type == "User"` → `Human: <login>` （例: `Human: alice`）
  - `user.type == "Bot"` → 下記マッピング表で表示名に正規化:

  | login パターン | 表示名 |
  |---|---|
  | `coderabbitai[bot]` | CodeRabbit |
  | `devin-ai-integration[bot]` | Devin |
  | `copilot-pull-request-reviewer[bot]` / `github-copilot[bot]` | Copilot |
  | `claude[bot]` | Claude |
  | 上記以外の `*[bot]` | login から `[bot]` サフィックスを除去し、ハイフン/アンダースコアを空白に変換してタイトルケース化（例: `foo-bar[bot]` → `Foo Bar`） |

- **優先度**: 下記の判定シグナルから決める。複数該当する場合は左の列が優先（明示プレフィックス > 絵文字 > 内容判断）。

  | シグナル | 値の例 | 優先度 |
  |---|---|---|
  | 本文先頭の角括弧プレフィックス | `[must]` | 🔴 Must |
  | 〃 | `[imo]` / `[ask]` / `[fyi]` | 🟡 Investigate |
  | 〃 | `[nits]` | 🟢 Info |
  | 本文先頭の絵文字 + キーワード | `🔴` / `Critical:` / `Must:` | 🔴 Must |
  | 〃 | `🟡` / `Warning:` / `Investigate:` | 🟡 Investigate |
  | 〃 | `🟢` / `Suggestion:` / `Info:` | 🟢 Info |
  | プレフィックス無し（内容で判断） | バグ・セキュリティ問題・破壊的変更 | 🔴 Must |
  | 〃 | 設計の検討余地・要判断項目 | 🟡 Investigate |
  | 〃 | スタイル・軽微な提案・情報提供 | 🟢 Info |

  Resolved 済みのコメントも、元の深刻度ラベルはそのまま残す（Must だったバグが Resolved されても Must のまま。ただし Summary 末尾の `✅ Resolved` で対応済みを示す）。

### 出力フォーマット

ユーザーへの提示はテーブル形式で行う。file:line が取れない（API が `line = null` を返す outdated diff など）場合は `src/foo.ts:?` と表記する。

```
## PR Review Comments Summary

| ID | Priority | Reviewer | File | Summary |
|----|----------|----------|------|---------|
| #1 | 🔴 Must | CodeRabbit | src/auth.ts:42 | Null check missing before accessing user.id |
| #2 | 🟡 Investigate | Devin | src/api.ts:15 | Consider using async/await instead of .then() ✅ Resolved |
| #3 | 🟢 Info | Human: alice | src/utils.ts:8 | Unused import statement |
...

### Details

**#1** 🔴 Must — CodeRabbit — src/auth.ts:42
> Original comment text here...
Intent: Prevent potential runtime error when user object is undefined

**#2** 🟡 Investigate ✅ Resolved — Devin — src/api.ts:15
> Original comment text here...
Intent: Code style suggestion for better readability
Resolution: 返信スレッド (reply by Devin): "Fixed in abc123" / "✅ Resolved in latest commit"

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
