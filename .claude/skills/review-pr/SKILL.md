---
name: review-pr
description: Comprehensive PR review with parallel multi-agent analysis, optional inline comment posting
disable-model-invocation: true
---

# Review PR

GitHub PR に対して下記「エージェント一覧」のレビュアーを `trigger` に従って並列起動し、統合サマリーを提示する。承認があれば Pending Review としてインラインコメントを投稿する。

```
引数解析 → 差分取得 → トリガー評価 → エージェント並列 → 指摘の集約 → 統合サマリー → 確認 → Pending Review 投稿
```

## エージェント一覧

「どのエージェントがどの条件で起動するか」の唯一の所在。観点を追加・廃止するときはこの表に行を足す/消すだけ。skill 本文の他の箇所には**エージェント名・トリガー条件をハードコードしない**。

| エージェント名        | trigger                                       | 一次責任                                                                     |
| --------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- |
| `code-reviewer`       | `always`                                      | 品質・設計・可読性・パフォーマンス・テスト                                   |
| `security-reviewer`   | `always`                                      | セキュリティ脆弱性 (OWASP Top 10 等。XSS / SQL injection 等の一次責任はここ) |
| `typescript-reviewer` | `extensions=.ts, .tsx, .js, .jsx, .mjs, .cjs` | 型安全性・非同期・JS/TS イディオム (`any` の濫用等の一次責任はここ)          |
| `postgres-reviewer`   | `always`                                      | Postgres 設計・クエリ・インデックス・RLS・接続管理 (生 SQL / ORM DML / Markdown DB 仕様。DB に関する記述がなければ即終了) |

`trigger` 列の値:

- `always` — 無条件で起動
- `paths=<glob...>` (省略可で `; exclude_paths=<glob...>`) — `paths` のいずれかが差分ファイルにマッチし、`exclude_paths` にマッチしないとき起動
- `extensions=<.ext...>` — 差分ファイルの拡張子のいずれかが該当するとき起動

新しい観点の追加 = 既存エージェント (例: `~/.claude/agents/code-reviewer.md`) を手本に `~/.claude/agents/<観点>-reviewer.md` を作り、**この表に 1 行追加する**。

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

#### 絶対行番号の取り方

各 reviewer agent は指摘ごとに **元ファイルの絶対行番号** (= Phase 5 のインライン投稿に使う `line`) を返す必要がある。diff だけからはハンクヘッダの相対位置しか分からないので、agent が以下を組み合わせる:

- **追加/変更行 (`side: RIGHT`)**: ハンクヘッダ `@@ -X,Y +A,B @@` の `A` を起点に、ハンク内のコンテキスト行 (` ` 開始) と追加行 (`+` 開始) を 1 つカウントするごとに 1 ずつ加算する。削除行 (`-` 開始) はカウントしない
- **削除行 (`side: LEFT`)**: 同じ要領で `X` を起点に、コンテキスト行と削除行をカウントし、追加行はカウントしない
- **取れないケース**: ハンクが大きすぎて起点が確定できないときや、生成コード等で行番号自体が不安定なときは、`line` の代わりに `<関数名>` フォールバックで返す (集約側でインライン投稿対象から除外される)

skill が agent prompt に diff 全文を渡す際は、上記の数え方が再現できるよう `gh pr diff <number>` の生出力 (ハンクヘッダ込み) を整形せずに埋め込む。

### Phase 2: トリガー評価とエージェント並列実行

「エージェント一覧」各行の `trigger` を `.files[].path` に対して評価。起動対象が決まったら、**同一メッセージ内の独立した Agent ツール呼び出し**で並列起動する。各エージェントへ渡す prompt は次の節構成にする:

```
## PR メタ
<タイトル / 本文 / ベース・ヘッドブランチ名>

## 差分
<gh pr diff の生出力をハンクヘッダ込みで貼る>

## 既存コメント
<gh api ... /comments の出力>

## 出力フォーマット
<.claude/skills/review-pr/output-format.md の本文を丸ごと貼る>
```

`## 出力フォーマット` 節は全 reviewer 共通の構造化スキーマ・量のコントロール・本文トーンの単一情報源で、agent 定義側には記載していない。毎回貼ること。

観点は各エージェントの「一次責任」で大部分は分離されるが、ボーダーラインケースで複数エージェントが同箇所を指摘することはある。その場合は Phase 3 でマージする。

いずれかが失敗しても残りで続行し、失敗したエージェント名を統合サマリーに明記する。

### Phase 3: 指摘の集約

**責務**: エージェント横断で Findings を正規化・重複検出・マージし、後続フェーズが使う中間データ構造 (統合 Finding リスト) を作る。表示整形や Overview/Key Changes の生成は Phase 4、副作用を伴う投稿は Phase 5 で行う。

各エージェントは **Findings (構造化指摘ブロックのリスト)** を返す。各ブロックには `priority` / `file` / `line` / `side` / タイトル / 本文段落 / (任意の) 修正案 が含まれる (詳細は各 agent 定義の「出力フォーマット」節)。

エージェント側で「作者の意図 / 実行パスの完全検証 / 具体的な影響」のフィルタは既に適用済みなので、本フェーズで再フィルタはしない。

#### 集約手順

1. **正規化** — 各 Finding を `{priority, file, line, side, title, body, suggestion?, source}` の内部表現に揃える。`source` には起動したエージェント名 (`code-reviewer` 等) を入れる
2. **重複検出** — 以下のいずれかに該当する Finding 群を 1 クラスタにまとめる:
   - `file` + `line` が完全一致 (ただし根本原因が完全に独立しているとき — 例: 同じ行に偶然「セキュリティ脆弱性」と「命名規約違反」が並んだ場合 — はクラスタ化せず別 Finding として残す。判断基準は **両指摘の修正が互いに依存しないか** = 片方を直しても他方が残るか)
   - `file` が一致し、`line` が ±3 行以内かつ同一の根本原因を指している (タイトル/本文から判断)
   - `file` が一致し、片方が `<関数名>` フォールバックでもう片方が同関数内の絶対行番号
3. **マージ** — クラスタ内で 1 件の統合 Finding にまとめる:
   - `priority`: 最も高いもの (critical > warning > suggestion) を採用
   - `source`: 全エージェント名を併記 (例: `security-reviewer, typescript-reviewer`)
   - `title`: priority 高の Finding の title を主軸にし、低 priority 側に固有情報があれば括弧書きで補足する
   - `body`: priority 高 → 低の順で段落を並べる。両方に固有情報がある場合のみ統合し、片方が冗長な再説明なら捨てる
   - `suggestion`: priority 高の suggestion を採用。同 priority で両方ある場合は「指摘行をそのまま単純置換できる方」を優先 (Suggested Changes に変換できるため)
   - `line` / `side`: 絶対行番号を持つ方を優先 (フォールバックより具体的)
4. **集計** — 起動したエージェントごとに Findings 件数を数える。マージ済みクラスタは関与した各エージェント列に 1 件ずつ計上 (合計は単純和ではない、クラスタ数)

本フェーズの出力 (統合 Finding リスト + 集計) は Phase 4 と Phase 5 の入力として再利用される。

### Phase 4: 統合サマリーの提示

**責務**: Phase 3 の集約結果と、親が diff から生成する Overview / Key Changes を組み合わせて、ユーザー向けの統合サマリーを表示する。

#### Overview

Summary 1 文（ビジネス/プロダクト背景を含む平易な表現）と Type/Scope/Impact/Size の表を記載する。レビュアーが 5 秒で PR を理解できることを狙う。**親が PR タイトル・本文・diff サマリから生成する** (エージェント出力は使わない)。

#### Key Changes

ファイルごとに読み物として解説する。レビュアーが差分を開く前に全体像を把握できるようにする。**親が diff から生成する** (エージェント出力は使わない)。

- 読み順は変更の性質に合わせる:
  - 実装コード中心: データ構造/ドメインモデル → コアロジック → 統合/オーケストレーション → UI → テスト
  - ドキュメントのみ: 意思決定 (ADR) → 概要 (README) → データ → 振る舞い (API) → UI (画面)
- 各ファイルは **`#### N.`** 見出しブロック (Markdown のナンバードリストは使わない)
  - 見出し: `#### N.` + 太字バッククォートのファイルパス + `(new)`/`(modified)`/`(deleted)`/`(renamed)`
  - 本文: (a) アーキテクチャ上の役割、(b) 本 PR での変更と理由、(c) 前後ファイルとの繋がり、(d) 非自明な設計判断・トレードオフ
  - 重要なコードスニペットはインラインコメント付きで引用し、Claude Code でのレンダリングのため `>` ブロッククォートで囲む
- プロジェクト固有の用語・略語は初出時に短く補足する

#### Findings

Phase 3 の統合 Finding リストをテーブル形式で出す (箇条書き不可)。指摘がない場合は本文に `No findings.` と書く (空テーブルは描画しない、セクション自体は省略しない)。

各行に含める列:
- **#** (連番、Phase 5 で投稿対象を選ぶ番号と一致)
- **優先度** (`priority` を絵文字付きで表示: 🔴 Critical / 🟡 Warning / 🟢 Suggestion)
- **出典** (`source`。複数エージェント由来は併記)
- **ファイル:行** (絶対行番号がなければ `file (関数名)` フォールバック)
- **問題** (タイトル + 本文から要約)
- **推奨対応** (具体的な修正案)

#### 集計テーブル

- 行は `🔴 Critical` / `🟡 Warning` / `🟢 Suggestion` の 3 行のみ (「計」行なし)
- 列は **Phase 2 のトリガー評価で起動を決定したエージェント分のみ** + `合計` (トリガーで除外したエージェントの列は出さない)
  - Findings 0 件のエージェントも列を残す (「起動して 0 件」と「起動しなかった」は別)
  - `postgres-reviewer` が DB 記述なしで即終了した場合も「起動して 0 件」扱いで列を残す
- マージ済みクラスタは各出典列に 1 件ずつ計上し、`合計` はクラスタ数 (列の単純和ではない)

### Phase 5: Pending Review 投稿（オプション）

統合サマリー提示後、**ユーザーに投稿対象の指摘番号を尋ねる** (例: `1,3,5` / `all` / `skip`)。

- `skip` → 表示のみで終了
- それ以外 → 選ばれた指摘を Pending Review のインラインコメントとして投稿
- **submit はユーザーに委ねる** (Pending 状態のまま残す)

番号を尋ねる際、フォールバック指摘 (`<関数名>` 形式で行番号未確定) はインライン投稿不可なので、その番号を `(投稿不可: 行番号未確定)` と明示する。例: `投稿可能: 1,2,4 / 投稿不可: 3 (行番号未確定のため Findings テーブルにのみ残す)`。

#### 指摘 → コメントへのマッピング

指摘テーブル 1 行 = 1 インラインコメント。

- `path` ← ファイル:行 のファイル部分
- `line` ← **元ファイルの絶対行番号** (diff ハンク内の相対位置ではない)
  - `side: "RIGHT"` のとき PR 適用後 (head) の絶対行番号、`side: "LEFT"` のとき PR 適用前 (base) の絶対行番号
  - 絶対行番号が取れない指摘 (`file (function_name)` フォールバック) はインライン投稿不可。選択肢から除外し、Phase 4 の Findings テーブルには残す
- `side` ← 追加/変更行は `RIGHT`、削除行は `LEFT`
- `body` ← エージェントが返した **タイトル + 本文段落** をそのまま使う。整形しない:
  ```
  {絵文字} {一文サマリ}

  {本文: 自然な文章}

  {必要なら修正案コードブロック}
  ```
  - **タイトル行 (絵文字 + 一文サマリ) は必ず先頭に残す**。インラインコメント先頭の「何の指摘か」を 1 行で伝える目印で、レビュイーがコメント一覧を流し読みするときに最重要となる。本文段落だけ転記してタイトルが落ちる事故を起こさない
  - 優先度ラベル (`**Critical**` 等) は冒頭の絵文字で表現済みなのでコメント本文では繰り返さない。指摘テーブル (Phase 4) で優先度・出典は別途担保される
- **修正案は可能な限り Suggested Changes として投稿する** (GitHub の ```` ```suggestion ```` ブロック)。エージェントが返した修正案コードブロックをこの形式に変換する:
  - 変換可能な条件: 修正が **指摘行 (または範囲)** の単純置換で表せる。中身は置換後の最終形そのもの (前後の文脈・コメント・余分な空行は含めない)
  - GitHub 側で `line` (単一行) または `start_line` + `line` (範囲) に対する完全置換として解釈されるため、コメントの `line`/`side` がそのまま置換範囲になる。エージェントが範囲指摘 (start_line を持つ) を返した場合はそれを使う
  - **通常コードブロックのまま残す** ケース: 別ファイルへの修正、import 追加、構造説明、複数の独立変更を含むなど、単純置換で表せないもの。エージェントが既に通常ブロック (```` ```ts ```` 等) で返している場合は変換せずにそのまま投稿する

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
