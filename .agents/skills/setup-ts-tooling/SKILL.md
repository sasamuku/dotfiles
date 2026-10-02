---
name: setup-ts-tooling
description: TypeScript プロジェクトの初期フェーズに必要な品質チェック・テスト・CI 補助ツールを選択して導入する。lint・整形は Biome を使う。
---

# Setup TS Tooling

初期フェーズの開発基盤を対象に、選択されたツールの依存・設定・実行スクリプト・必要な CI 連携を導入し、実行して検証する。E2E・カバレッジ計測・HTTP モック・パッケージ公開・リリースノート生成・モノレポのキャッシュ最適化は選択肢に含めない。

## 選択

対象の指示、package.json、lockfile、Node の版、workspace、既存の CI・設定・Git hook を確認する。パッケージマネージャと既存の運用を維持する。

ツール指定がある場合はその選択で進める。未指定なら、次の表から用途に合う候補を既存導入済みと区別して提示し、一度の質問で選択を受け取る。選択前に依存を追加しない。「おすすめで導入」と依頼された場合は、既存構成を優先し、型検査・Biome・Vitest・GitHub Actions を初期候補として、用途に不要なものを外して進める。テスト基盤が既にあれば置き換えない。

連携先が必要な選択（commitlint の Git hook、pinact の実行場所など）は既存の仕組みを使う。追加ツールが必要なら選択時に合わせて提示し、未選択の Lefthook・mise 等を暗黙に追加しない。

| 用途 | 選択肢 | 選ぶ条件・重複関係 |
|---|---|---|
| 依存管理 | pnpm / npm / Yarn | 既存を維持。新規はユーザー指定を優先し、未指定なら pnpm |
| 型検査 | TypeScript（tsc） | framework の型生成が必要なら既存の typecheck 経路を使う |
| lint・整形 | Biome | lint・整形は Biome に統一。既存の別ツールからの移行が必要なら、その差分を示して選択を受け取る |
| 未使用コード・依存 | Knip | entry・workspace・生成物を対象 PJ に合わせる |
| ユニット・結合テスト | Vitest | Node / DOM / Workers 等の実行環境に合わせる |
| CI | GitHub Actions | GitHub の PJ。別の CI があるなら依頼なく追加・移行しない |
| Workflow 検査 | actionlint / ghalint / zizmor | それぞれ構文・ポリシー・セキュリティの検査。個別に選択可能 |
| Actions の SHA 固定 | pinact | GitHub Actions の参照固定が必要な場合 |
| 依存更新 | Renovate / Dependabot | 同じ依存の更新を二重運用しない。automerge は明示指定時だけ |
| Git hook | Lefthook | 既存の管理ツールを重複導入しない |
| コミット規約 | commitlint | Conventional Commits を採用する場合 |
| シークレット検査 | gitleaks | ローカル・CI の実行場所を選択する。検出値をログに露出しない |
| Markdown リンク検査 | lychee | ローカルリンクと外部 URL の検査範囲を明示する |
| 開発 CLI 管理 | mise | Node や npm 管理外 CLI の版を揃える場合。既存の版管理と競合させない |
| PR ラベル | Release Drafter Autolabeler | PR タイトルからの分類が必要な場合。リリース下書き生成は導入しない |
| コードの脆弱性解析 | CodeQL | GitHub の JS/TS 解析。リポジトリの公開範囲・プランの利用条件を確認する |

## 導入

- 選んだツールだけ公式ドキュメントで現在の設定形式、対応 Node・framework・package manager、互換バージョンを確認する。特定 PJ の版や設定をそのまま流用しない。
- 既存ファイルは必要箇所だけ統合し、scripts・hook・workflow を丸ごと置き換えない。設定済みなら不足分だけ補い、再実行で重複を増やさない。
- 依存は対象 workspace の適切な場所に追加し、lockfile を更新する。lint / format / typecheck / test 等は既存の命名を優先し、CI とローカルで同じ scripts を呼ぶ。
- GitHub Actions を選んだ場合は `.github/workflows/ci.yml` を作成し、既存 workflow があれば統合する。新規 CI は PR と既定ブランチへの push を契機とし、選択したチェックと既存の build script を実行する。未選択・未定義の scripts は呼ばない。CI の lint・整形チェックは書き換えなしで行う。
- CLI の版は既存の管理方法で固定する。GitHub Actions は確認できた完全な commit SHA と版コメントで固定し、必要な permissions・timeout を設定する。Node・package manager の版ソースとキャッシュを PJ に合わせ、CI の依存インストールでは lockfile を変更しない。
- 型生成が必要なチェックは生成後に実行する。生成物・build 出力を lint や未使用検査へ誤って含めない。
- テスト基盤を選んだ場合は PJ の実際の機能に対する最小のテストを実行する。機能がまだなければ基盤・test script だけ導入し、CI のテストステップは最初の実テスト追加まで保留と報告する。ダミーテストや `passWithNoTests` で成功扱いにしない。
- Autolabeler 等の書き込みジョブは品質チェックと権限を分離する。fork・Dependabot の PR ではトークンが読み取り専用になる点を考慮し、書き込み不要の CI を妨げない。`pull_request_target` を使う場合は PR 側のコードを checkout・実行しない。
- Renovate App、CodeQL、Secrets など GitHub 側の設定が必要なら、ファイルの導入と外部側の有効化を分けて報告する。デプロイ・公開は対象外とし、自動マージの有効化は明示指定時だけ行う。

## 検証

導入したツールの実コマンドと関連する既存チェックを実行し、差分に未選択ツールや不要な設定がないことを確認する。生成した workflow の scripts・版ファイル・lockfile・作業ディレクトリの参照先を確認し、actionlint が利用可能なら構文・式も検査する。CI 専用ツールも実行可能ならローカルで検査する。実行できないチェック、GitHub 側の未設定、実行履歴未確認を成功扱いにしない。

変更内容・変更ファイル・実行した検証・残リスクを報告する。

## 公式資料

- [Biome](https://biomejs.dev/guides/getting-started/): lint・整形導入時
- [Vitest](https://vitest.dev/guide/): ユニット・結合テスト導入時
- [Dependabot](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependabot-version-updates)・[CodeQL](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-code-scanning): GitHub の依存更新・コード解析導入時
