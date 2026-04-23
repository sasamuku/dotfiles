---
name: review-pr
description: Comprehensive PR review with parallel code + security analysis, optional inline comment posting
disable-model-invocation: true
---

# Review PR

GitHub PR に対して **code-reviewer** と **security-reviewer** を並列実行し、統合サマリーを提示する。承認があれば Pending Review としてインラインコメントを投稿する。

```
引数解析 → 差分取得 → 2エージェント並列 → 統合サマリー → 確認 → Pending Review 投稿
```

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
gh pr view <number>
gh pr diff <number>
gh repo view --json nameWithOwner --jq '.nameWithOwner'
gh api repos/{owner}/{repo}/pulls/{number}/comments
gh api repos/{owner}/{repo}/pulls/{number}/reviews
```

差分が空なら「レビュー対象の差分がありません」と報告して終了する。

### Phase 2: 並列レビュー実行

**同一メッセージ内の独立した Agent ツール呼び出し**として並列起動する。各エージェントには PR タイトル・説明・差分・既存コメントを渡す。

- **code-reviewer**: 品質・設計・可読性・パフォーマンス・テスト
- **security-reviewer**: OWASP Top 10 を含むセキュリティ

### Phase 3: 統合サマリー

#### Overview

レビュアーが 5 秒で PR を理解できるよう、Summary 1 文（ビジネス/プロダクト背景を含む平易な表現）と Type/Scope/Impact/Size の表を記載する。

#### Key Changes

ファイルごとに読み物として書く解説。レビュアーが差分を開く前に全体像を把握できるようにする。

- 読み順を決める。一般的な順序: データ構造/ドメインモデル → コアロジック → 統合/オーケストレーション → UI → テスト
- 各ファイルは **`#### N.`** 見出しブロックで記述する（Markdown のナンバードリストは使わない — ネストした番号付けの競合を避けるため）
  - 見出し: `#### N.` + 太字バッククォートのファイルパス + `(new)`/`(modified)`/`(deleted)`/`(renamed)`
  - 本文: プロジェクト初参加者向けに、(a) ファイルのアーキテクチャ上の役割、(b) この PR での変更と理由、(c) 読み順上の前後ファイルとの繋がり、(d) 非自明な設計判断・トレードオフ
  - 重要なコードスニペットをインラインコメント付きで引用（Claude Code でのレンダリングのため `>` ブロッククォートで囲む）
- プロジェクト固有の用語・略語は初出時に短く補足

#### Findings

指摘を書く前に、以下のフィルタを**順番に**適用し、通らない指摘は除外する:

1. **作者の意図** — 周辺コード・コールサイトを読み、合理的な意図的設計があればフラグを立てない
2. **実行パスの完全検証** — エンドツーエンドで追う。並行性はトランザクション境界とロック取得をすべて辿る。単一箇所だけを根拠にしない
3. **具体的な影響** — 観測可能なバグや障害を具体的に述べる。「理論的にありえる」「一貫性のため」といった根拠では不十分。現実的な破綻シナリオを説明できなければフラグを立てない
4. **指摘数の下限なし** — 指摘ゼロは有効かつ良い結果。クリーンな PR はクリーンなレビューに値する

指摘がない場合は本文に `No findings.` と書く（空テーブルは描画しない、セクション自体は省略しない）。指摘はテーブル形式（箇条書き不可）。

各指摘に含める要素:
- **優先度** (上記「優先度分類」)
- **出典** (`code-reviewer` / `security-reviewer` / 両方)
- **ファイル:行** (絶対行番号が取れない場合は `file (function_name)` にフォールバック)
- **問題の説明**
- **具体的な修正案**

両エージェントが同一箇所を指摘したら統合し、出典欄に両方を記載する。

**集計テーブルの記載ルール**:
- Priority の行は `🔴 Critical` / `🟡 Warning` / `🟢 Suggestion` の 3 行のみ。「計」行は出力しない
- 統合された指摘は `code-reviewer` 列 と `security-reviewer` 列にそれぞれ 1 件ずつ計上し、`合計` 列も 1 件とする（左 2 列の和ではない）

### Phase 4: Pending Review 投稿（オプション）

統合サマリー提示後、**ユーザーに投稿対象の指摘番号を尋ねる**。例: 「投稿する指摘の番号を教えてください（例: `1,3,5` / `all` で全件 / `skip` で投稿せず終了）」。

- `skip` が選ばれた場合は表示のみで終了する
- それ以外は選ばれた指摘のみを Pending Review のインラインコメントとして投稿する
- **submit はユーザーに委ねる**（Pending 状態のまま残す）

#### 指摘 → コメントへのマッピング

指摘テーブル 1 行 = 1 インラインコメント。以下の通り変換する:

- `path` ← ファイル:行 のファイル部分
- `line` ← ファイル:行 の行番号（**元ファイルの絶対行番号**であり、diff ハンク内の相対位置ではない）
  - `side: "RIGHT"` のとき: PR 適用後のファイル（head）の絶対行番号
  - `side: "LEFT"` のとき: PR 適用前のファイル（base）の絶対行番号
  - 絶対行番号が取れなかった指摘（`file (function_name)` フォールバック）はインライン投稿不可。選択肢から除外し、Phase 3 の表には残す
- `side` ← 追加/変更行は `RIGHT`、削除行は `LEFT`
- `body` ← 以下のテンプレートで組み立てる:
  ```
  {絵文字} **{優先度}**: {問題の説明}

  {具体的な修正案}
  ```

#### 手順

**1. 既存 Pending Review を確認**（自分が作成したもののみ対象にする。他人のレビューを誤って操作しないため）:

```bash
ME=$(gh api user --jq .login)
gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews \
  --jq ".[] | select(.state == \"PENDING\") | select(.user.login == \"$ME\") | {id, state, user: .user.login}"
```

**2a. Pending Review なし → REST API で新規作成**

`event` フィールドを**省略**すると pending 状態になる（`event: "PENDING"` を明示すると `422`）:

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

**2b. Pending Review あり → GraphQL でコメント追加**（REST では既存 pending にコメント追加不可）

Node ID を取得する:

```bash
ME=$(gh api user --jq .login)
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

コメントを追加する:

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
| PR 番号が特定できない | エラーを表示して終了する |
| 空の差分 | 「レビュー対象の差分がありません」と報告して終了する |
| エージェントの片方が失敗 | もう片方の結果で続行し、失敗を明記する |
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

ここから読む。このプロジェクトでは認証フローの失敗モードを区別するためにカスタムエラークラスを使っている。本 PR では期限切れトークンでパスワードリセットが試みられたときに送出する `TokenExpiredError` を導入する。専用クラスとして定義することで、後段のミドルウェア (#3) で個別に捕捉でき、汎用の 500 ではなく 401 を返せる。

> ```ts
> // src/errors.ts:1-6
> // ミドルウェアが "期限切れトークン" を他の認証エラーと区別し、
> // 汎用 500 ではなく 401 を返せるようにするための専用エラークラス。
> export class TokenExpiredError extends Error {
>   constructor(message = "Reset token has expired") {
>     super(message);
>   }
> }
> ```

このクラスは auth.ts (#2) と middleware.ts (#3) の両方から import される。

#### 2. **`src/auth.ts`** (変更)

（同様の解説 + コードスニペット引用）

#### 3. **`src/middleware.ts`** (変更)

（同様の解説 + コードスニペット引用）

---

### 指摘事項

| # | 優先度 | 出典 | ファイル | 問題 | 推奨対応 |
|---|-------|------|---------|------|---------|
| 1 | 🔴 Critical | security-reviewer | src/auth.ts:42 | サニタイズされていない入力による SQL インジェクション | パラメータ化クエリを使用する |
| 2 | 🟡 Warning | code-reviewer | src/api.ts:15 | 非同期呼び出しでエラーハンドリングが欠落 | try-catch を追加し、エラーを適切に伝播させる |
| 3 | 🟢 Suggestion | code-reviewer | src/utils.ts:8 | ロジックの重複 | 共通ヘルパーに抽出する |

### 集計

| 優先度 | code-reviewer | security-reviewer | 合計 |
|---|---|---|---|
| 🔴 Critical | 0 | 1 | 1 |
| 🟡 Warning | 1 | 0 | 1 |
| 🟢 Suggestion | 1 | 0 | 1 |
````
