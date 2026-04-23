---
name: review-pr
description: Comprehensive PR review with code analysis and feedback
disable-model-invocation: true
---

# Review PR

GitHub Pull Request の徹底的なコードレビューを実施する。

## 引数

$ARGUMENTS

- **第 1 引数** (必須): PR 番号または PR URL (例: `123` または `https://github.com/owner/repo/pull/123`)

## 手順

1. PR の情報と差分を取得する:
   ```bash
   gh pr view <number>
   gh pr diff <number>
   ```

2. コンテキスト用の既存レビューコメントを取得する:
   ```bash
   gh api repos/{owner}/{repo}/pulls/{number}/comments
   gh api repos/{owner}/{repo}/pulls/{number}/reviews
   ```

3. **code-reviewer** エージェントを使い、PR タイトル・説明・差分・既存コメントを渡してレビューを実施する。

4. **Overview** セクションを書く。目標は、レビュアーが 5 秒で PR を理解できるようにすること:
   - Summary: 平易な言葉で 1 文にまとめる — プロジェクト初日のメンバーでもなぜこの PR が存在するのかわかるように、ビジネス/プロダクトの**背景**を含める
   - Type, Scope, Impact, Size — レビュアーが労力とリスクを一目で把握できるよう表を埋める

5. **Key Changes** セクションを書く — PR の変更をファイルごとに物語として説明するナラティブ。レビュアーが差分を開く前に全体像を理解できるようにする:

   - 差分を分析し、最適な読み順を決定する。一般的な順序: データ構造/ドメインモデル → コアロジック → 統合/オーケストレーション → UI/プレゼンテーション → テスト/ストーリー。
   - 各ファイルに **`#### N.` 見出しブロック** (例: `#### 1.`, `#### 2.`) を書く。Markdown のナンバードリスト (`1.` を行頭に置く形式) は使わない — ネストした番号付けの競合を避けるため `####` 見出しを使う:
     - 見出し行: `#### N.` の後にファイルパスを太字バッククォートで記述し、`(new)`, `(modified)`, `(deleted)`, `(renamed)` のいずれかをタグとして付ける
     - 2 行目以降: プロジェクトに参加したばかりの人に説明するように書く。以下を網羅する:
       - このファイルがコードベースで担う役割 (アーキテクチャ上のコンテキスト)
       - この PR で具体的に何が変更・追加されたか、そしてその理由
       - 読み順における前後のファイルとの繋がり
       - 特筆すべき非自明な設計上の決定やトレードオフ
     - 説明を具体的にするため、重要なコードスニペットをインラインコメント付きで引用する。レビュアーが差分の中で何を見ればよいかわかるよう、最も重要な型・関数シグネチャ・ロジックブロックを示す。Claude Code の出力で正しくレンダリングされるよう、コードブロックは `>` ブロッククォートで囲む。
   - プロジェクト固有の用語・略語・ドメインジャーゴンが登場する場合は、初出時に短い説明をインラインで補足する。
   - このセクションを読めば、作者にコンテキストを確認しなくても差分を自信を持ってレビューできる状態にする。

6. **Findings** セクションを書く。指摘を書く前に、以下のフィルタを**順番に**適用する。いずれかのフィルタを通過しない指摘は必ず除外する:

   **フィルタ 1 — 作者の意図**: 「なぜ作者はこのように書いたのか?」を問う。周辺のコード、コールサイト、関連ファイルを読み、意図的な設計が存在するか確認する。合理的な意図的設計が見つかれば、フラグを立てない。

   **フィルタ 2 — 実行パスの完全検証**: 実行パスをエンドツーエンドで追う。並行性に関する懸念は、すべてのトランザクション境界とロック取得をたどって確認する。状態管理については、すべてのプロデューサーとコンシューマーを追跡する。単一のコード箇所だけを根拠にフラグを立てない。

   **フィルタ 3 — 具体的な影響**: 発生しうる具体的で観測可能なバグや障害を明確に述べる。「理論的にありえる...」「一貫性のため...」では不十分。コードが実際に壊れる現実的なシナリオを説明できない場合はフラグを立てない。

   **フィルタ 4 — 指摘数の下限なし**: 指摘ゼロは有効かつ良い結果である。出力を生み出すために指摘を作り上げたり基準を下げたりしない。クリーンな PR はクリーンなレビューに値する。

   指摘がない場合は、セクション本文に `No findings.` と書く。空のテーブルを描画せず、セクション自体も省略しない。

   指摘は後述の出力フォーマットのテーブル形式で示す。箇条書きは使わない。

   全フィルタを通過した各指摘について:
   - 優先度を分類する:
     - 🔴 **Critical** - セキュリティ脆弱性、バグ、データロスのリスク
     - 🟡 **Warning** - コード品質の懸念事項、潜在的な問題
     - 🟢 **Suggestion** - 改善提案、スタイル、可読性
   - ファイルと行番号を指定する (例: `src/auth.ts:42`)。差分から絶対行番号が特定できない場合 (ハンクヘッダーのみの場合など) は、`file (function_name)` または `file (symbol_name)` 形式にフォールバックする
   - 問題を簡潔に説明する
   - 修正方法の具体的な推奨事項を示す

## 出力フォーマット

````
## PR Review Summary

### Overview

> Users were unable to reset their password because the reset token was not validated before use, allowing expired tokens to succeed.

| | |
|---|---|
| **Type** | Bug fix |
| **Scope** | Authentication — password reset flow |
| **Impact** | Expired reset links will now correctly show an error instead of silently succeeding |
| **Size** | 3 files changed, +45 / -12 lines |

### Key Changes

#### 1. **`src/errors.ts`** (new)

Start here. This project uses custom error classes to distinguish between different failure modes in the authentication flow. This PR introduces `TokenExpiredError`, thrown when a user attempts a password reset with an expired token. By giving it a dedicated class, downstream code (middleware in #3) can catch it specifically and return the correct HTTP status.

> ```ts
> // src/errors.ts:1-6
> // A dedicated error class so middleware can distinguish "expired token"
> // from other auth failures and return 401 instead of a generic 500.
> export class TokenExpiredError extends Error {
>   constructor(message = "Reset token has expired") {
>     super(message);
>   }
> }
> ```

Both auth.ts (#2) and middleware.ts (#3) import this type, so reading it first gives you the vocabulary for the rest of the PR.

#### 2. **`src/auth.ts`** (modified)

The core authentication module handling login, logout, and password reset. The bug being fixed is that `resetPassword()` previously accepted any structurally valid token without checking its expiry, so expired links silently succeeded. This PR adds `validateToken()` at the top of the reset flow:

> ```ts
> // src/auth.ts:12-18
> // Called before any password update — rejects stale tokens early
> // so no side effects (DB writes, emails) happen on invalid requests.
> function validateToken(token: string) {
>   if (isExpired(token)) {
>     throw new TokenExpiredError("Reset token has expired");
>   }
> }
> ```

This function throws the `TokenExpiredError` defined in #1. The next file (#3) handles what happens when this error reaches the HTTP layer.

#### 3. **`src/middleware.ts`** (modified)

The centralized error-handling layer that translates domain exceptions into HTTP responses. This PR adds a catch clause for `TokenExpiredError` from #1:

> ```ts
> // src/middleware.ts:25-28
> // Without this clause, the TokenExpiredError from auth.ts
> // would bubble up as an unhandled 500.
> if (error instanceof TokenExpiredError) {
>   return res.status(401).json({ message: error.message });
> }
> ```

This ensures the client receives a meaningful 401 rejection instead of a confusing server error.

---

### Findings

| # | Priority | File | Issue | Recommendation |
|---|----------|------|-------|----------------|
| 1 | 🔴 Critical | src/auth.ts:42 | SQL injection via unsanitized input | Use parameterized queries |
| 2 | 🟡 Warning | src/api.ts:15 | Missing error handling in async call | Add try-catch with proper error propagation |
| 3 | 🟢 Suggestion | src/utils.ts:8 | Duplicated logic | Extract into shared helper |
...
````
