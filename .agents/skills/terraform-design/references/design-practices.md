# 設計判断とリファレンス

整理日: 2026-10-08。Future (Future Architect 社の Terraform ガイドライン) は設計の選択肢と推奨。HashiCorp は Terraform の仕様と推奨。AWS の資料は AWS 向けの補足。要件に応じて採否を判断し、資料全体に準拠していると無条件には宣言しない。

## 論点別早見表

| 論点・資料 | 尊重するプラクティス | 適用時の注意 |
|---|---|---|
| Future: [環境分離](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#環境分離) | 環境ディレクトリと module 再利用を組み合わせる | 既存の環境選択方式、隔離要件、環境差を見る。環境の数と名前は要件から決める |
| Future: [モジュール化対象](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#モジュール化対象) | ライフサイクルが近い resource をまとめ、薄いラッパーを避ける | Future は 5〜10 resource 以上を目処と示すが、数は合否基準にせず、機能のまとまりと入出力を見る |
| HashiCorp: [Module Composition](https://developer.hashicorp.com/terraform/language/modules/develop/composition) | 浅い module ツリーを root で組み立てる | 不要な階層や、特定製品の全設定を包む巨大な module を作らない。例外は必要性を具体的に説明する |
| HashiCorp: [Dependency Inversion](https://developer.hashicorp.com/terraform/language/modules/develop/composition#dependency-inversion) | 依存する resource を入力として受け取る | 作成済み / 新規の違いは呼び出し側で吸収し、child に取得・作成の分岐を持たせない |
| Future: [入力設計](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#入力設計)・[機能配置](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#機能配置) | 入力を絞り、型・説明・検証を付ける。環境ごとに機能を有効にするかは呼び出し側で決める | 安全な既定値と必須入力を区別する。大量の設定を object に詰めて丸ごと渡す構成を正当化しない |
| Future: [ステートの粒度](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#ステートの粒度) | ネットワーク・管理基盤・アプリなど、ライフサイクルの異なる単位で state の分離を検討する | 分割によって増える実行順序・参照・復旧の負担も比較する。DB と compute の state 分離は必須ではない |
| HashiCorp: [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers) | provider 設定は root、要件は各 module。alias は明示的に渡す | アカウント・リージョンの選択と provider 要件を混同しない |
| HashiCorp: [Standard Module Structure](https://developer.hashicorp.com/terraform/language/modules/develop/structure) | main・variables・outputs・README を標準の構成で用意する | 大きな定義はファイルを分けてよいが、ファイル分割は module 境界ではない |
| AWS: [Terraform code structure](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/structure.html) | AWS の機能としてまとまる module と、呼び出し側での組み立てを重視する | AWS 向け設計のときだけ補足資料として使う。AWS 固有の前提を他クラウドへ適用しない |

## state・移行を扱うときの追加参照

- Future の [ステートの粒度](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#ステートの粒度) は、state 間の値参照に data source (タグで検索する例) を推奨する。取得できる属性、一意性、読取権限、依存先がまだ構築されていないときの挙動を確認する。公開 output やパラメータストアとも比較し、タグ検索を無条件に正解としない
- [HashiCorp: S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3): AWS で state の保存先を設計するとき、ロック・権限・保存先の仕様を利用バージョンと照合する
- [HashiCorp: Refactor modules](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring): 既存 state を保って module を移動・改名するときに読む。新規構築と同じ手順にしない
- [HashiCorp: Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock): provider の選択結果と再現性を確認する。Future は lock file を Git の管理対象外とする方針を示すが、無条件には採用せず、HashiCorp の推奨・既存運用との違いを説明する

bootstrap とは、state 保存先バケットなど backend より先に必要な resource の初期構築を指す。そこで一時的に使う local state も機密情報として扱い、Git へ保存しない。Future の bootstrap 例は state の commit を許容するが、本スキルでは採用しない。

## 根拠と説明の書き方

「root で output → input を接続する」は参照資料のプラクティスである。「この resource 群を別 module にする」は対象コードからの設計判断であり、責務・参照関係・変更単位の根拠を添える。

共通 module を使う環境が増えるほど、module のコードを修正したときの影響先も増える。環境横断の plan 確認、段階適用、バージョン固定は運用要件から選ぶ。再利用しただけで安全性や性能が保証される、という説明はしない。
