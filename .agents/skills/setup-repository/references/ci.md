# CI・Workflow 検査

| 用途 | 選択肢 | 選ぶ条件・重複関係 |
|---|---|---|
| CI | GitHub Actions | GitHub の PJ。別の CI があるなら依頼なく追加・移行しない |
| Workflow 検査 | actionlint / ghalint / zizmor | それぞれ構文・ポリシー・セキュリティの検査。個別に選択可能 |
| Actions の SHA 固定 | pinact | GitHub Actions の参照固定が必要な場合 |
| PR ラベル | Release Drafter Autolabeler | PR タイトルからの分類が必要な場合。リリース下書き生成は導入しない |
| コードの脆弱性解析 | CodeQL | GitHub の JS/TS 解析。リポジトリの公開範囲・プランの利用条件を確認する |

- GitHub Actions を選んだ場合は `.github/workflows/ci.yml` を作成し、既存 workflow があれば統合する。新規 CI は PR と既定ブランチへの push を契機とし、選択したチェックと既存の build script を実行する。未選択・未定義の scripts は呼ばない。CI の lint・整形チェックは書き換えなしで行う。

- CLI の版は既存の管理方法で固定する。GitHub Actions は確認できた完全な commit SHA と版コメントで固定し、必要な permissions・timeout を設定する。Node・package manager の版ソースとキャッシュを PJ に合わせ、CI の依存インストールでは lockfile を変更しない。

- Autolabeler 等の書き込みジョブは品質チェックと権限を分離する。fork・Dependabot の PR ではトークンが読み取り専用になる点を考慮し、書き込み不要の CI を妨げない。`pull_request_target` を使う場合は PR 側のコードを checkout・実行しない。

生成した workflow の scripts・版ファイル・lockfile・作業ディレクトリの参照先を確認する。actionlint が利用可能なら構文・式も検査する。CI 専用ツールも実行可能ならローカルで検査する。

[CodeQL 公式資料](https://docs.github.com/en/code-security/concepts/code-scanning/codeql/codeql-code-scanning)で利用条件を確認する。
