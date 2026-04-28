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

### ステップ 4: 価値判定 (任意拡張)

**トリガー**: ユーザーが priority 分類とは別に「対応すべきか否か」の判断を明示要求した場合のみ実行する。明示要求がなければ飛ばす。

**前提**: priority は **深刻度**、Value は **このユーザーがこの PR で対応すべきか** を示す独立軸。Must でも Value=No (既存問題・別 PR スコープ) や Info でも Value=Yes (1 行修正) はあり得る。

**判定ラベル**:

- ✅ **Yes** — この PR で対応すべき
- ❌ **No** — 対応しない (理由を明記)
- 🤔 **保留** — ユーザー判断が必要 (別 PR 推奨 / チーム方針依存 / 情報不足)

**判定軸** (最低 2 軸を明示する):

| 軸 | Yes 寄り / No・保留 寄り |
|---|---|
| 実害サイズ | 確認済み実害あり / 理論上のみ |
| 修正コスト | 1 箇所完結 / 大規模リファクタ → 保留 |
| 現 PR スコープ適合 | 同一スコープ / 別スコープ → 保留 (別 PR) |
| 変更前から存在 | 本 PR で導入 / 既存問題 → No or 保留 |

実害サイズが不明な場合は妥当な仮定を 1 文添える (例: "Sentry に類似エラーなしの前提")。別 PR で追跡する価値があれば 🤔 保留、なければ ❌ No。

**出力テーブルに `Value` 列を追加する**:

```
| ID | Priority | Value | Reviewer | File | Summary |
|----|----------|-------|----------|------|---------|
| #1 | 🔴 Must | ✅ Yes | CodeRabbit | src/auth.ts:42 | Null check missing — Sentry で実害確認 |
| #2 | 🔴 Must | 🤔 保留 (別 PR) | CodeRabbit | src/legacy.ts:15 | SQL injection — ただし変更前から存在 |
| #3 | 🟢 Info | ✅ Yes | Copilot | src/utils.ts:8 | 未使用 import — 1 行削除で完了 |
```

Details セクションには `Value Reasoning` 行 (1〜2 文) を追加する:

```
**#2** 🔴 Must 🤔 保留 — CodeRabbit — src/legacy.ts:15
> Original comment text here...
Intent: SQL injection 脆弱性の排除
Value Reasoning: 変更前から存在する問題で本 PR スコープ外。別 Issue で追跡を推奨。
```

**重複指摘の統合** (任意): 同一 path + 近接行 (±5 行以内) + 同一趣旨のコメントは 1 グループにまとめ、Value 判定を 1 回だけ出す。代表は「最高 priority かつ最初の行番号」、他は Reviewer 列に `/` 区切りで併記 (`CodeRabbit / Claude / Devin`)。

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
