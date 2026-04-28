---
name: review-pr
description: Comprehensive PR review with parallel multi-agent analysis, optional inline comment posting
disable-model-invocation: true
---

# Review PR

GitHub PR に対して下記「エージェント一覧」のレビュアーを `trigger` に従って並列起動し、統合サマリーを提示する。承認があれば Pending Review としてインラインコメントを投稿する。

```
引数解析 → 差分取得 → トリガー評価 → エージェント並列 → 統合サマリー → 確認 → Pending Review 投稿
```

## エージェント一覧

「どのエージェントがどの条件で起動するか」の唯一の所在。観点を追加・廃止するときはこの表に行を足す/消すだけ。skill 本文の他の箇所には**エージェント名・トリガー条件をハードコードしない**。

| エージェント名        | trigger                                       | 一次責任                                                                     |
| --------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- |
| `code-reviewer`       | `always`                                      | 品質・設計・可読性・パフォーマンス・テスト                                   |
| `security-reviewer`   | `always`                                      | セキュリティ脆弱性 (OWASP Top 10 等。XSS / SQL injection 等の一次責任はここ) |
| `typescript-reviewer` | `extensions=.ts, .tsx, .js, .jsx, .mjs, .cjs` | 型安全性・非同期・JS/TS イディオム (`any` の濫用等の一次責任はここ)          |

`trigger` 列の値:

- `always` — 無条件で起動
- `paths=<glob...>` (省略可で `; exclude_paths=<glob...>`) — `paths` のいずれかが差分ファイルにマッチし、`exclude_paths` にマッチしないとき起動
- `extensions=<.ext...>` — 差分ファイルの拡張子のいずれかが該当するとき起動

新しい観点の追加 = 既存エージェント (例: `~/.claude/agents/code-reviewer.md`) を手本に `~/.claude/agents/<観点>-reviewer.md` を作り、**この表に 1 行追加する**。

## 優先度分類

- 🔴 **Critical** — セキュリティ脆弱性、バグ、データロスのリスク
- 🟡 **Warning** — コード品質の懸念、潜在的な問題
- 🟢 **Suggestion** — 改善提案、スタイル、可読性

## 引数

$ARGUMENTS

優先順:
1. **PR番号** (`^\d+$` / `^#\d+$`): `gh pr diff <番号>`
2. **PR URL** (`github.com` を含む): URL から番号抽出 → `gh pr diff`
3. **引数なし**: `gh pr view --json number --jq '.number'` で現ブランチから自動検出

## 手順

### Phase 1: 情報収集

```bash
gh pr view <number> --json number,title,body,baseRefName,headRefName,files
gh pr diff <number>
gh repo view --json nameWithOwner --jq '.nameWithOwner'
gh api repos/{owner}/{repo}/pulls/{number}/comments
gh api repos/{owner}/{repo}/pulls/{number}/reviews
```

差分が空なら「レビュー対象の差分がありません」と報告して終了する。

`.files[].path` を控える (Phase 2 のトリガー評価で使う)。

### Phase 2: トリガー評価とエージェント並列実行

「エージェント一覧」各行の `trigger` を `.files[].path` に対して評価。起動対象が決まったら、**同一メッセージ内の独立した Agent ツール呼び出し**で並列起動する。各エージェントへの引き渡し:

- PR タイトル・本文・ベース/ヘッドブランチ名
- `gh pr diff` の差分全文
- 既存インラインコメント一覧

観点は各エージェントの「一次責任」で大部分は分離されるが、ボーダーラインケースで複数エージェントが同箇所を指摘することはある。その場合は Phase 3 でマージする。

いずれかが失敗しても残りで続行し、失敗したエージェント名を統合サマリーに明記する。

### Phase 3: 統合サマリー

#### Overview

Summary 1 文（ビジネス/プロダクト背景を含む平易な表現）と Type/Scope/Impact/Size の表を記載する。レビュアーが 5 秒で PR を理解できることを狙う。

#### Key Changes

ファイルごとに読み物として解説する。レビュアーが差分を開く前に全体像を把握できるようにする。

- 読み順を決める (一般的には: データ構造/ドメインモデル → コアロジック → 統合/オーケストレーション → UI → テスト)
- 各ファイルは **`#### N.`** 見出しブロック (Markdown のナンバードリストは使わない)
  - 見出し: `#### N.` + 太字バッククォートのファイルパス + `(new)`/`(modified)`/`(deleted)`/`(renamed)`
  - 本文: (a) アーキテクチャ上の役割、(b) 本 PR での変更と理由、(c) 前後ファイルとの繋がり、(d) 非自明な設計判断・トレードオフ
  - 重要なコードスニペットはインラインコメント付きで引用し、Claude Code でのレンダリングのため `>` ブロッククォートで囲む
- プロジェクト固有の用語・略語は初出時に短く補足する

#### Findings

指摘前に以下のフィルタを**順番に**適用し、通らない指摘は除外する:

1. **作者の意図** — 周辺コード・コールサイトを読み、合理的な意図があればフラグを立てない
2. **実行パスの完全検証** — エンドツーエンドで追う。並行性はトランザクション境界とロック取得をすべて辿る
3. **具体的な影響** — 「理論的にありえる」「一貫性のため」は不十分。現実的な破綻シナリオを説明できなければ立てない
4. **指摘数の下限なし** — 指摘ゼロは良い結果

指摘がない場合は本文に `No findings.` と書く (空テーブルは描画しない、セクション自体は省略しない)。指摘はテーブル形式 (箇条書き不可)。

各指摘に含める要素:
- **優先度** (上記「優先度分類」)
- **出典** (冒頭テーブルの `エージェント名` をそのまま使う。複数エージェントが同一箇所を指摘したら統合し、出典欄にすべて併記)
- **ファイル:行** (絶対行番号が取れない場合は `file (function_name)` にフォールバック)
- **問題の説明**
- **具体的な修正案**

**集計テーブル**:
- 行は `🔴 Critical` / `🟡 Warning` / `🟢 Suggestion` の 3 行のみ (「計」行なし)
- 列は **Phase 2 で起動したエージェント分のみ** (起動しなかったエージェントの列は出さない)
- 統合された指摘は各出典列に 1 件ずつ計上し、`合計` も 1 件とする (列の単純和ではない)

### Phase 4: Pending Review 投稿（オプション）

統合サマリー提示後、**ユーザーに投稿対象の指摘番号を尋ねる** (例: `1,3,5` / `all` / `skip`)。

- `skip` → 表示のみで終了
- それ以外 → 選ばれた指摘を Pending Review のインラインコメントとして投稿
- **submit はユーザーに委ねる** (Pending 状態のまま残す)

#### 指摘 → コメントへのマッピング

指摘テーブル 1 行 = 1 インラインコメント。

- `path` ← ファイル:行 のファイル部分
- `line` ← **元ファイルの絶対行番号** (diff ハンク内の相対位置ではない)
  - `side: "RIGHT"` のとき PR 適用後 (head) の絶対行番号、`side: "LEFT"` のとき PR 適用前 (base) の絶対行番号
  - 絶対行番号が取れない指摘 (`file (function_name)` フォールバック) はインライン投稿不可。選択肢から除外し、Phase 3 の表には残す
- `side` ← 追加/変更行は `RIGHT`、削除行は `LEFT`
- `body` ← 下記テンプレート:
  ```
  {絵文字} **{優先度}**: {問題の説明}

  {具体的な修正案}
  ```

#### 手順

**1. 既存 Pending Review を確認** (自分が作成したもののみ対象):

```bash
ME=$(gh api user --jq .login)
gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews \
  --jq ".[] | select(.state == \"PENDING\") | select(.user.login == \"$ME\") | {id, state, user: .user.login}"
```

**2a. Pending Review なし → REST API で新規作成**

`event` フィールドを**省略**すると pending 状態になる (`event: "PENDING"` を明示すると `422`):

```bash
cat <<'PAYLOAD' | gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews --method POST --input -
{
  "comments": [
    {
      "path": "src/example.ts",
      "line": 10,
      "side": "RIGHT",
      "body": "🔴 **Critical**: SQL injection via unsanitized input\n\nUse parameterized queries."
    }
  ]
}
PAYLOAD
```

**2b. Pending Review あり → GraphQL でコメント追加** (REST では既存 pending にコメント追加不可)

Node ID 取得 → コメント追加:

```bash
gh api graphql -f query="
{
  repository(owner: \"{owner}\", name: \"{repo}\") {
    pullRequest(number: {PR番号}) {
      reviews(states: PENDING, first: 20) {
        nodes { id state author { login } }
      }
    }
  }
}" --jq ".data.repository.pullRequest.reviews.nodes[] | select(.author.login == \"$ME\")"
```

```bash
cat <<'GQL' | gh api graphql --input -
{
  "query": "mutation($input: AddPullRequestReviewThreadInput!) { addPullRequestReviewThread(input: $input) { thread { id comments(first: 1) { nodes { id body } } } } }",
  "variables": {
    "input": {
      "pullRequestReviewId": "PRR_kwDOxxxxxxx",
      "path": "src/example.ts",
      "line": 10,
      "side": "RIGHT",
      "body": "コメント本文"
    }
  }
}
GQL
```

## エラーハンドリング

| シナリオ | 対応 |
|---|---|
| いずれかのエージェントが失敗 | 残りの結果で続行し、失敗したエージェントを明記する |
| Pending Review 作成失敗 | エラー内容を表示し、統合サマリーはユーザーに残す |

## 出力フォーマット

````
## PR レビューサマリー

### 概要

> パスワードリセット時にリセットトークンの有効期限を検証していなかったため、期限切れのトークンでもリセットが成功してしまう不具合を修正する。

| | |
|---|---|
| **種別** | バグ修正 |
| **スコープ** | 認証機能 — パスワードリセットフロー |
| **影響** | 期限切れのリセットリンクが、これまで通ってしまっていたのを正しくエラーとして返すようになる |
| **規模** | 3 ファイル変更、+45 / -12 行 |

### 主な変更

#### 1. **`src/errors.ts`** (新規)

ここから読む。認証フローの失敗モードを区別するためのカスタムエラークラスとして `TokenExpiredError` を導入。ミドルウェア (#3) で個別捕捉して汎用 500 ではなく 401 を返せるようにする。

> ```ts
> // src/errors.ts:1-6
> export class TokenExpiredError extends Error {
>   constructor(message = "Reset token has expired") {
>     super(message);
>   }
> }
> ```

auth.ts (#2) と middleware.ts (#3) の両方から import される。

#### 2. **`src/auth.ts`** (変更)

（同様の解説 + コードスニペット引用）

#### 3. **`src/middleware.ts`** (変更)

（同様の解説 + コードスニペット引用）

---

### 指摘事項

| # | 優先度 | 出典 | ファイル | 問題 | 推奨対応 |
|---|-------|------|---------|------|---------|
| 1 | 🔴 Critical | security-reviewer, typescript-reviewer | src/auth.ts:42 | サニタイズされていない入力による SQL インジェクション | パラメータ化クエリを使用する |
| 2 | 🟡 Warning | typescript-reviewer | src/api.ts:15 | 非同期呼び出しで未処理の Promise rejection | `await` + try-catch でエラーを伝播させる |
| 3 | 🟢 Suggestion | code-reviewer | src/utils.ts:8 | ロジックの重複 | 共通ヘルパーに抽出する |

出典列には冒頭テーブルの `エージェント名` をそのまま入れる (上記は例示)。

### 集計

起動したエージェント分の列のみ出す (例: TS/JS 変更がない PR では `typescript-reviewer` 列を省略する)。

| 優先度 | code-reviewer | security-reviewer | typescript-reviewer | 合計 |
|---|---|---|---|---|
| 🔴 Critical | 0 | 1 | 1 | 1 |
| 🟡 Warning | 0 | 0 | 1 | 1 |
| 🟢 Suggestion | 1 | 0 | 0 | 1 |
````
