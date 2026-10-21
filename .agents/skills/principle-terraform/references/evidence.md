# 根拠の示し方

設計の根拠は、参照資料のプラクティスと、対象コードから導いた設計判断に分けて示す。2 つを混ぜると、資料が言っていないことまで資料の権威で通すことになる。

## 判断の観点

- **プラクティスと設計判断を書き分ける**: 「root で output を input に渡す」は、資料のプラクティスである。「この resource 群を別の module にする」は、対象コードからの設計判断であり、責務、参照関係、変更の単位という根拠が要る。
- **全面準拠を宣言しない**: 資料のどの節を尊重し、どこを適用しないかを示す。資料全体に従うとは書かない。
- **数値の目安を合否にしない**: 資料の数値 (Future の「5〜10 resource 以上」など) は目安であり、合否の基準ではない。
- **バージョンと照らす**: バージョンに依存する仕様は、使っている Terraform と provider のバージョンと照合する。確かめられないものは、未確認と書く。
- **再利用は安全の証明ではない**: 共通の module を使う環境が増えるほど、module を直したときの影響先も増える。再利用しただけで、安全性や性能が保証されるわけではない。
- **個別の判断を共通の決まりにしない**: 過去のプロジェクトや資料での個別の判断を、そのまま別のプロジェクトに当てはめない。AWS 向けの資料の前提を、他のクラウドに当てはめない。

## 資料の早見表

整理日: 2026-10-08。Future (Future Architect 社の Terraform ガイドライン) は設計の選択肢と推奨、HashiCorp は Terraform の仕様と推奨、AWS の資料は AWS 向けの補足である。

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
