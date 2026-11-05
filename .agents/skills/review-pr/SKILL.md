---
name: review-pr
description: Review a GitHub PR with parallel specialists, verify and consolidate findings, and optionally post selected comments as a pending review.
disable-model-invocation: false
---

# Review PR

引数: $ARGUMENTS (PR番号・URL、省略時は現在のブランチ)。URL 指定時は対象リポジトリも解決する。

## エージェント一覧

依頼する場面・一次責任はこの表を正本とする。

| エージェント名        | 依頼する場面                                   | 一次責任                                                                     |
| --------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------- |
| `security-reviewer`   | 外部からの入力、認証・認可、秘密情報、外部との通信、依存の追加・更新、権限の設定に触れる | セキュリティ脆弱性 (OWASP Top 10 等。XSS / SQL injection 等の一次責任はここ) |
| `typescript-reviewer` | `.ts` `.tsx` `.js` `.jsx` `.mjs` `.cjs` のロジックの変更 | 型安全性・非同期・JS/TS イディオム (`any` の濫用等の一次責任はここ)          |
| `postgres-reviewer`   | SQL、マイグレーション、ORM のクエリやスキーマ、DB 設計の文書の変更 | Postgres 設計・クエリ・インデックス・RLS・接続管理 (生 SQL / ORM DML / Markdown DB 仕様) |
| `terraform-reviewer`  | `.tf` `.tfvars` `.hcl` の変更                  | Terraform: module と state の境界・backend・環境の取り違え・保護の喪失、AWS の構成 (principle-terraform / principle-aws-architecture に準拠) |
| `ponytail-reviewer`   | 関数・抽象・依存の追加など、コードが増える変更 | 過剰設計: 不要な依存・推測的抽象・stdlib/ネイティブ機能の再実装・短縮可能なロジック (「削れるか」のみ。正しさ・セキュリティ・性能は扱わない) |
| `standard-reviewer`   | コードの変更を含む。ほかのどの reviewer にも当たらない変更もここに入る | 役割・観点を与えない素のレビュー (他の reviewer と範囲が重なってよい) |
| `meta-reviewer`       | 新しい機能、仕組みの変更、回避策など、何を解くかの判断を含む | メタ認知: 問題設定・前提・構造 (症状対処になっていないか / 上流に軽い解はないか / そもそもやるべきか)。指摘は `scope: PR` の PR-level ブロックのみで、行単位指摘はしない |

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

## Phase 2: reviewer の選定と並列実行

親がマネージャーとして、PR の目的と diff から依頼する reviewer を決める。表の「依頼する場面」に当たり、起動のコスト (1 体ごとに diff 全体を読む) に見合う指摘が見込めるものだけを選ぶ。一次責任が重なるなら、差分により近い 1 体にする。選んだ reviewer と見送った reviewer は、理由を 1 行ずつ添えて Phase 4 で示す。

選んだ reviewer を並列起動する。各 prompt には PRタイトル・本文・base/head、生の diff (ハンクヘッダ込み)、既存指摘、[output-format.md](output-format.md) の内容を渡す。失敗した reviewer があれば残りで続け、未実施の観点を報告する。

## Phase 3: 指摘の集約と検証

1. 指摘を `{priority,file,line,side,title,body,suggestion?,source}` に揃える。
2. 同ファイル・同根本原因の指摘を統合する (同一行、近接 ±3 行、同関数の行番号/関数名フォールバック)。同じ行でも修正が独立する問題は分ける。
3. 出典を併記し、重複説明を削る。優先度は高い方を起点に実害で調整し、修正案は単純置換できるものを優先する。
4. **独立検証**: 統合した指摘 1 件ごとに、読み取り専用の新しいサブエージェントを並列で起動する。渡すのは PR タイトル・本文、diff、その指摘 1 件だけにし、ほかの指摘と出典の reviewer は渡さない。検証役は head のコードと呼び出し元を読み、指摘の主張が成り立つかを `確認` / `否定` / `判定不能` で判定し、根拠の `file:line` を添えて返す。ローカルの HEAD が head と違えば、`git fetch origin pull/<number>/head` の後に `git show FETCH_HEAD:<path>` と `git grep <pattern> FETCH_HEAD` で読む。
5. **最終フィルタ4テスト**を親が適用する:
   - 実害: 放置時の現実的な影響を1文で説明できるか。条件付きなら前提を示す。
   - 対応価値: 作者が直せる問題か。好みだけの指摘は除く。
   - 根拠: 手順 4 で `確認` されたか。`否定` と `判定不能` は除く。
   - 差分内: 本PRの変更行が修正対象か。差分外の問題は捨てず、投稿対象外の「既存の問題」に回す。

`scope: PR` は同じ根本原因のものだけ統合し、手順 4 と、根拠・差分内の 2 テストを適用しない。行に紐付かないためインライン投稿しない。フィルタで除外した指摘は、判断に必要なものだけ理由を添えて観察事項に残す。指摘ゼロでもよい。

## Phase 4: 統合サマリーの提示

変更の目的を短く示し、指摘を `番号 / 優先度 / 出典 / ファイル:行 / 問題と対応` の表で提示する。ゼロなら「指摘なし」。既存の問題は同じ列の別の表にする。PR全体への問い・未実施の観点・重要な観察事項があれば添える。

全ファイルの解説・コード引用・集計表は、依頼された場合か判断に必要な場合だけ出す。集計する場合、複数 reviewer の重複を合計件数で二重計上しない。

## Phase 5: Pending Review 投稿 (任意)

サマリーを見てユーザーが選んだ指摘番号 (`all` / `skip` も可) のみ投稿する。行番号未確定・PR全体の指摘と既存の問題は選択対象外と明示する。
投稿する場合だけ [posting.md](posting.md) を読み、Pending 状態に残す。submit はユーザーに委ねる。
