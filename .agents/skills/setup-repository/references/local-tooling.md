# ローカル開発ツール

| 用途 | 選択肢 | 選ぶ条件・重複関係 |
|---|---|---|
| Git hook | Lefthook | 既存の管理ツールを重複導入しない |
| コミット規約 | commitlint | Conventional Commits を採用する場合 |
| シークレット検査 | gitleaks | ローカル・CI の実行場所を選択する。検出値をログに露出しない |
| Markdown リンク検査 | lychee | ローカルリンクと外部 URL の検査範囲を明示する |
| 開発 CLI 管理 | mise | Node や npm 管理外 CLI の版を揃える場合。既存の版管理と競合させない |

連携先が必要な選択では既存の仕組みを使う。commitlint の Git hook や pinact の実行場所などは選択時に確認し、未選択の Lefthook・mise 等を暗黙に追加しない。CLI の版は既存の管理方法で固定する。
