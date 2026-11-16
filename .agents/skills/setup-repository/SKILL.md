---
name: setup-repository
description: リポジトリの初期セットアップや開発基盤の追加に使う。GitHub テンプレート・ラベル、TypeScript の品質チェック・テスト、CI、依存更新・脆弱性検査、ローカル開発ツールを選択して導入する。
disable-model-invocation: true
---

# Setup Repository

依頼されたカテゴリのガイドだけを読み、選択された設定・ツールを導入して検証する。カテゴリの指定だけで、掲載されたツールをすべて導入しない。

| カテゴリ | 読むガイド |
|---|---|
| Issue・PR テンプレート、実ラベル | [GitHub テンプレート](references/github-templates.md) |
| 依存管理、型検査、Biome、Knip、Vitest | [TypeScript](references/typescript.md) |
| GitHub Actions、Workflow 検査、SHA 固定、PR 自動ラベル、CodeQL | [CI](references/ci.md) |
| Renovate・Dependabot、OSV-Scanner | [依存更新・脆弱性検査](references/dependencies.md) |
| Git hook、commitlint、シークレット検査、リンク検査、CLI の版管理 | [ローカル開発ツール](references/local-tooling.md) |

## 選択

対象の指示、依存ファイル・lockfile、実行環境の版、workspace、既存の CI・設定・Git hook を確認する。パッケージマネージャと既存の運用を維持する。

ツール指定がある場合はその選択で進める。未指定なら、関連カテゴリから用途に合う候補を既存導入済みと区別して提示し、一度の質問で選択を受け取る。選択前に依存を追加しない。連携に追加ツールが必要なら合わせて提示し、未選択のツールを暗黙に追加しない。

TypeScript で「おすすめで導入」と依頼された場合は、既存構成を優先し、型検査・Biome・Vitest・GitHub Actions を初期候補として、用途に不要なものを外す。テスト基盤が既にあれば置き換えない。

初期フェーズの開発基盤を対象に、選択されたツールの依存・設定・実行スクリプト・必要な CI 連携を導入し、実行して検証する。E2E・カバレッジ計測・HTTP モック・パッケージ公開・リリースノート生成・モノレポのキャッシュ最適化は選択肢に含めない。


## 導入・検証

- 選んだツールだけ公式ドキュメントで現在の設定形式、対応 Node・framework・package manager、互換バージョンを確認する。特定 PJ の版や設定をそのまま流用しない。
- 既存ファイルは必要箇所だけ統合し、scripts・hook・workflow を丸ごと置き換えない。設定済みなら不足分だけ補い、再実行で重複を増やさない。
- 導入したツールの実コマンドと関連する既存チェックを実行し、差分に未選択ツールや不要な設定がないことを確認する。
- GitHub 側の設定が必要なら、ファイルの導入と外部側の有効化を分けて報告する。Secrets などの未設定、実行履歴の未確認、実行できないチェックを成功扱いにしない。
- デプロイ・公開は対象外とし、自動マージの有効化は明示指定時だけ行う。

変更内容・変更ファイル・実行した検証・残リスクを報告する。
