---
name: review-pr
description: Review a GitHub PR with parallel specialists, verify and consolidate findings, and optionally post selected comments as a pending review.
---

# Review PR

引数: $ARGUMENTS (PR番号・URL、省略時は現在のブランチ)。URL 指定時は対象リポジトリも解決する。

## エージェント一覧

起動条件・一次責任はこの表を正本とする。

| エージェント名        | trigger                                       | 一次責任                                                                     |
| --------------------- | --------------------------------------------- | ---------------------------------------------------------------------------- |
| `code-reviewer`       | `always`                                      | 品質・設計・可読性・パフォーマンス・テスト                                   |
| `security-reviewer`   | `always`                                      | セキュリティ脆弱性 (OWASP Top 10 等。XSS / SQL injection 等の一次責任はここ) |
| `typescript-reviewer` | `extensions=.ts, .tsx, .js, .jsx, .mjs, .cjs` | 型安全性・非同期・JS/TS イディオム (`any` の濫用等の一次責任はここ)          |
| `postgres-reviewer`   | `content=sql\|migrat\|schema\|prisma\|drizzle\|typeorm\|sequelize\|knex\|sqlalchemy\|active_?record\|postgres\|supabase\|\brls\b\|row.?level.?security\|create (table\|policy\|index)\|alter table` | Postgres 設計・クエリ・インデックス・RLS・接続管理 (生 SQL / ORM DML / Markdown DB 仕様。DB に関する記述がなければ即終了) |
| `ponytail-reviewer`   | `always`                                      | 過剰設計: 不要な依存・推測的抽象・stdlib/ネイティブ機能の再実装・短縮可能なロジック (「削れるか」のみ。正しさ・セキュリティ・性能は扱わない) |
| `meta-reviewer`       | `always`                                      | メタ認知: 問題設定・前提・構造 (症状対処になっていないか / 上流に軽い解はないか / そもそもやるべきか)。指摘は `scope: PR` の PR-level ブロックのみで、行単位指摘はしない |

- `always`: 常に起動。
- `extensions=`: 変更ファイルの拡張子に一致。
- `paths=` (任意で `; exclude_paths=`): 変更パスが glob に一致し、除外対象でない。
- `content=`: パスを含む diff 生出力に大文字小文字を区別せず正規表現が一致。

## Phase 1: 情報収集

```bash
gh pr view <number> --json number,title,body,baseRefName,headRefName,files
gh pr diff <number>
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate \
  --jq '[.[] | {path,line,side,body,user:.user.login}]'
gh api repos/{owner}/{repo}/pulls/{number}/reviews --paginate \
  --jq '[.[] | {state,body,user:.user.login}]'
```

PR本文を意図・範囲の判断に使い、既存指摘との重複を避ける。空差分なら終了する。コメントの不要な JSON フィールドは渡さない。

### 絶対行番号の取り方

ハンク `@@ -X,Y +A,B @@` の RIGHT は A、LEFT は X が起点。コンテキスト行は両側、追加行は RIGHT、削除行は LEFT のみ進める。行番号は diff 内の位置ではなく元ファイルの絶対行番号。確定できなければ関数名で返し、投稿対象から外す。

## Phase 2: トリガー評価とエージェント並列実行

表の条件を評価し、該当する reviewer を並列起動する。各 prompt には PRタイトル・本文・base/head、生の diff (ハンクヘッダ込み)、既存指摘、[output-format.md](output-format.md) の内容を渡す。失敗した reviewer があれば残りで続け、未実施の観点を報告する。

## Phase 3: 指摘の集約

1. 指摘を `{priority,file,line,side,title,body,suggestion?,source}` に揃える。範囲指定も保持する。
2. 同ファイル・同根本原因の指摘を統合する (同一行、近接 ±3 行、同関数の行番号/関数名フォールバック)。同じ行でも修正が独立する問題は分ける。
3. 出典を併記し、重複説明を削る。優先度は高い方を起点に実害で調整し、修正案は単純置換できるものを優先する。
4. **最終フィルタ4テスト**を親が適用する:
   - 実害: 放置時の現実的な影響を1文で説明できるか。条件付きなら前提を示す。
   - 対応価値: 作者が直せる問題か。好みだけの指摘は除く。
   - 根拠: 周辺コード・呼び出し元を確認し、実行経路や仕様の思い込みを除く。
   - 差分内: 本PRの変更行が修正対象か。差分外は投稿対象にしない。

`scope: PR` は同じ根本原因のものだけ統合し、4番目のテストを除外する。行に紐付かないためインライン投稿しない。フィルタで除外した指摘は、判断に必要なものだけ理由を添えて観察事項に残す。指摘ゼロでもよい。

## Phase 4: 統合サマリーの提示

変更の目的を短く示し、指摘を `番号 / 優先度 / 出典 / ファイル:行 / 問題と対応` の表で提示する。ゼロなら「指摘なし」。PR全体への問い・未実施の観点・重要な観察事項があれば添える。

全ファイルの解説・コード引用・集計表は、依頼された場合か判断に必要な場合だけ出す。集計する場合、複数 reviewer の重複を合計件数で二重計上しない。

## Phase 5: Pending Review 投稿 (任意)

サマリーを見てユーザーが選んだ指摘番号 (`all` / `skip` も可) のみ投稿する。行番号未確定・PR全体の指摘は選択対象外と明示する。
投稿する場合だけ [posting.md](posting.md) を読み、Pending 状態に残す。submit はユーザーに委ねる。
