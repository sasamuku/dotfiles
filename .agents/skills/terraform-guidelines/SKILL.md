---
name: terraform-guidelines
description: Terraform の設計・レビュー・運用の判断基準。新規構成の設計、既存構成のレビュー (環境分離・root/child module・state 境界)、state backend と CI 権限の初回構築 (bootstrap)、公式資料と公開ガイドラインに基づく設計判断の根拠づけをケース別の参照資料で扱う。
---

# Terraform Guidelines

共通原則をここに置き、ケースごとの手順と根拠は `references/` に分ける。該当するケースの資料だけ読む。

## 共通原則

- 対象クラウド・サービス・環境・既存資産・求める成果物を会話とコードから確認する。確認できない点は仮定を明記して進め、成果物に未確認として残す
- 判断は公式資料と公開ガイドラインを根拠にし、資料全体への準拠を無条件に宣言しない。バージョン依存の仕様は利用バージョンと照合し、参照できない情報は未確認と明記する
- 設計のみの依頼では apply と state 操作をしない。Issue・PR など外部への投稿は、明示的に依頼されたときだけ
- 定義数・行数は count / for_each 適用後の resource 数とは別物であり、分割や規模の根拠にしない
- state と local state の退避ファイルは機密情報として扱い、Git に保存しない

## ケース別の参照先

| ケース | 読む資料 |
|---|---|
| 新規構成の設計。既存構成のレビュー (root / child module の責務、環境分離、state 境界、入出力と依存関係) | [design-review.md](references/design-review.md) |
| state backend・CI 権限の初回構築 (bootstrap)。local から S3 への state 移行。bootstrap 方式の比較 | [state-bootstrap.md](references/state-bootstrap.md) |
| 設計判断の根拠にする資料の早見表 (Future、HashiCorp、AWS) と、根拠の書き方 | [practices.md](references/practices.md) |

ケースが複数にまたがるときは、設計 → bootstrap の順に読む。設計レビューの成果物に bootstrap 手順を含めるときも、state 操作は実装フェーズまで行わない。
