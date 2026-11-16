# 依存更新・脆弱性検査

| 用途 | 選択肢 | 選ぶ条件・重複関係 |
|---|---|---|
| 依存更新 | Renovate / Dependabot | 同じ依存の更新を二重運用しない。automerge は明示指定時だけ |
| 依存パッケージの脆弱性検査 | OSV-Scanner | 対象の言語・lockfile が対応しているか確認する。依存更新とは別に選択する |

Renovate App など GitHub 側の設定が必要なら、ファイルの導入と外部側の有効化を分けて報告する。自動マージの有効化は明示指定時だけ行う。

[Dependabot 公式資料](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates)

[OSV-Scanner の対応形式](https://google.github.io/osv-scanner/supported-languages-and-lockfiles/)・[GitHub Actions 公式ガイド](https://google.github.io/osv-scanner/github-action/)
