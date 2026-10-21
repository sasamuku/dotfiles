# state

state は、Terraform が管理する実環境の正本である。失えば Terraform は実環境を管理できなくなり、漏れれば resource の属性が秘密情報ごと漏れる。だから state は、1 か所の共有された保存先に置いて守り、手元に残さない。

## 判断の観点

- **state は秘密情報**: local state とその退避ファイルには、resource の属性がそのまま入る。`*.tfstate*` と `.terraform/` は Git に入れない。
- **local state は一時的なもの**: 手元にしか無い state は、apply した人以外には再現も復旧もできない。local に置いてよいのは、backend がまだ存在しない最初の 1 回だけで、共有の保存先へ移したら消す。
- **分割は module と別に決める**: ネットワーク、管理基盤、アプリのように、ライフサイクルが違う単位で分けることを検討する。分けると、state 間での値の受け渡し、実行の順序、復旧の手間が増える。その負担と比べて決める。持ち主 (チーム) が違うなら分ける。DB と compute は結びつきが強いので、分けなくてよい。
- **state 間の値の受け渡しは比べて選ぶ**: data source によるタグ検索、`terraform_remote_state` での output の参照、パラメータストアは、取得できる属性、一意性、読み取り権限、依存先がまだ無いときの挙動がそれぞれ違う。`terraform_remote_state` は state 同士を強く結びつけ、state の統合や分割を難しくする。どれかを無条件に正解としない。
- **既存資産は state ごと保つ**: module の移動や改名は、`moved` や `import` で state を保ったまま行う。resource address が変わる変更を、作り直しで済ませない。

## backend の初回構築

backend の保存先 (S3 bucket など) と CI の権限は、backend より先に要る。この鶏と卵の問題の既定の解き方は、2 段階にすることである。最初の 1 回だけ local state で bootstrap root を apply し、作った bucket へ state を移す。以後は bootstrap root も共有の state で管理する。

- **bootstrap root に置くのは、backend と CI より先に要るものだけ**: state bucket、暗号化の鍵、OIDC provider、plan 用と apply 用の role。アプリの resource は置かない。bootstrap root は環境 (アカウント) ごとに 1 つ。
- **bootstrap は人が apply する**: CI の role を CI 自身が変更する構成にしない。
- **bucket は消されないように守る**: bucket を消すと、bootstrap 自身の state も消える。`prevent_destroy`、versioning、必要なら Object Lock で守る。

ほかの方式は、条件が合うときだけ選ぶ。

| 方式 | 選ぶ場面 | 注意 |
|---|---|---|
| Terragrunt の `remote_state` に bucket を作らせる | Terragrunt を既に使っている | bucket が Terraform の state の管理外になる |
| 外で作ってから import する | 手作業で作った bucket や role が既にある | 手作業が残り、コードは後追いになる |
| HCP Terraform などのマネージド backend | SaaS を使える組織 | 鶏と卵の問題そのものが消える |
| アカウントの発行時に用意する (Control Tower AFT など) | アカウントを継続的に作る組織 | 鶏と卵を、管理アカウントでの 1 回に押し上げる |

## 落とし穴

| 誤り | 正しい理解 |
|---|---|
| backend ブロックを書いてから、初回の `terraform init` をする | 存在しない bucket を探して失敗する。backend は bucket を作った後に足す |
| backend を変えるときに `terraform init -reconfigure` を使う | `-reconfigure` は state を移さない。移すのは `-migrate-state` (非対話なら `-force-copy`) |
| S3 backend のロックに DynamoDB を使う | DynamoDB のロックは非推奨になった。`use_lockfile = true` を使う (1.10 で導入、1.11 で GA) |
| CI の plan role に、state の key への読み書きだけを許す | plan もロックを取る。`<key>.tflock` への `s3:GetObject`、`s3:PutObject`、`s3:DeleteObject` が無いと、ロックの解放に失敗する |
| SSE-KMS の鍵を作り、bucket の権限だけを付ける | state を読み書きするすべての principal に、`kms:Encrypt`、`kms:Decrypt`、`kms:GenerateDataKey` が要る |
| 複数の root で同じ `key` を使う | root ごとに `key` を分ける (`network/terraform.tfstate`、`app/terraform.tfstate`) |
| bucket 名を環境名だけで付ける | S3 の汎用 bucket の名前は、partition 内のすべての account で一意である。product、環境、region、account を含めて衝突を避けるか、自分の account だけが使える account regional namespace に作る |
| lock file (`.terraform.lock.hcl`) を Git の管理対象外にする (Future の方針) | HashiCorp は、Git に入れて provider の選択を再現できるようにすることを推奨する。どちらを採るかは、違いを説明して決める |

## 出典

- Future Architect: [ステートの粒度](https://future-architect.github.io/arch-guidelines/documents/forTerraform/terraform_guidelines.html#ステートの粒度)
- AWS: [General purpose bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)
- HashiCorp: [Backend Configuration](https://developer.hashicorp.com/terraform/language/backend)、[terraform init](https://developer.hashicorp.com/terraform/cli/commands/init)、[S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)、[Refactor modules](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)、[Dependency lock file](https://developer.hashicorp.com/terraform/language/files/dependency-lock)
- [Terragrunt: State Backend](https://docs.terragrunt.com/features/state-backend)
- [cloudposse/terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend): 2 段階方式の実装例
