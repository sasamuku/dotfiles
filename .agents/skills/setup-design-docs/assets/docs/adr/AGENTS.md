# ADR ディレクトリ作業ルール

このディレクトリで ADR を作成・更新するときは、**まず [README.md](./README.md) を読み、その運用ルールに従うこと**。

特に:

- 新規 ADR は `TEMPLATE.md` をコピーして `NNNN-短いタイトル.md` を作る（番号は既存の最大 + 1、4 桁ゼロ埋め）。
- ステータスは `Proposed` → `Accepted` の流れで進める。
- Accepted 済みの ADR は書き換えない（不変）。方針変更は新しい ADR を起こし、旧 ADR を `Deprecated` / `Superseded` にする。
- 新規追加・ステータス変更をしたら、README.md の「一覧」テーブルも更新する。
