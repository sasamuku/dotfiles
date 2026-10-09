# state backend の bootstrap (2 段階方式)

整理日: 2026-10-09。対象は S3 backend を使う新規アカウント・環境。state 保存先と CI 権限は backend より先に必要なため、最初の 1 回だけ local state で apply し、直後に自分が作った bucket へ state を移す。以後は bootstrap root も S3 state で管理する。

## 原則

- bootstrap root は環境 (アカウント) ごとに 1 つ。置くのは「backend と CI より先に必要なもの」だけ: state bucket、暗号化鍵、OIDC provider、plan / apply 用 role。アプリ固有の resource は置かない
- local state は移行後に削除する。永続化すると apply した人の手元にしか state が無くなり、再現も復旧もできない
- bootstrap の apply 主体は人。CI role を CI 自身が変更する構成にしない
- `*.tfstate*` と `.terraform/` は `.gitignore` に入れる。local state には resource の属性がそのまま入る

## 手順

### 1. 前提を確認する

| 項目 | 確認内容 |
|---|---|
| 対象アカウント | account ID と region。provider の `allowed_account_ids` に使う |
| bucket 名 | S3 はグローバル一意。`<product>-<env>-<region>-<account>-tfstate` のように衝突しない命名にする |
| Terraform バージョン | S3 native lock (`use_lockfile = true`) は 1.10 で実験的導入、1.11 で GA。DynamoDB ロックは公式ドキュメントで非推奨 |
| 暗号化 | SSE-KMS なら KMS key も bootstrap root で作る。state を読み書きする全 principal (CI role、運用者) に `kms:Encrypt`、`kms:Decrypt`、`kms:GenerateDataKey` が必要 |
| 既存リソース | 手作業で作った bucket や role が既に存在するなら、新規作成せず「既存リソースの取り込み」の節へ |

### 2. bootstrap root を backend なしで書く

```hcl
# env/<env>/bootstrap/providers.tf
provider "aws" {
  region              = var.region
  allowed_account_ids = [var.account_id]
}

# env/<env>/bootstrap/main.tf
module "terraform_backend" {
  source      = "../../../modules/terraform-backend"
  bucket_name = local.state_bucket_name
  # versioning, SSE, public access block, TLS 必須の bucket policy, prevent_destroy を module 内で持つ
}

module "deployment_access" {
  source           = "../../../modules/deployment-access"
  state_bucket_arn = module.terraform_backend.bucket_arn
  github_repo      = var.github_repo
  # OIDC provider, plan role (読み取り + state RW), apply role (環境の protected branch / environment に限定)
}

output "state_bucket" { value = module.terraform_backend.bucket_name }
```

この時点で `backend` ブロックは書かない。書くと init が存在しない bucket を探して失敗する。

### 3. local state で apply する

```bash
cd env/<env>/bootstrap
terraform init
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
```

`terraform.tfstate` がこのディレクトリにできる。この間はディレクトリを他の人と共有しない。

### 4. backend を追記する

```hcl
# env/<env>/bootstrap/backend.tf
terraform {
  backend "s3" {
    bucket       = "<手順 3 の output の bucket 名>"
    key          = "bootstrap/terraform.tfstate"
    region       = "<region>"
    encrypt      = true
    use_lockfile = true
  }
}
```

`key` は root ごとに別にする。同じ bucket に `network/terraform.tfstate`、`app/terraform.tfstate` のように root 名で分ける。

### 5. state を移行する

```bash
terraform init -migrate-state
# "Do you want to copy existing state to the new backend?" に yes
```

非対話で実行するなら `-force-copy` (`-migrate-state` を含む)。`-reconfigure` は state を移さないので使わない。

### 6. 移行を確認し、local state を消す

```bash
terraform plan                    # No changes であること
aws s3 ls s3://<bucket>/bootstrap/ # terraform.tfstate があること
rm terraform.tfstate terraform.tfstate.backup
```

### 7. 他の root に backend を設定する

network / app などの root の `backend.tf` に同じ bucket と別の `key` を書き、通常どおり `terraform init` する。CI の plan role には `s3:GetObject` / `s3:PutObject` を各 key に、`s3:GetObject` / `s3:PutObject` / `s3:DeleteObject` を各 `<key>.tflock` に、`s3:ListBucket` を bucket に付ける。plan も state をロックするため、`.tflock` の権限が無いとロック解放に失敗する。

## 検証

- bootstrap root の `terraform plan` が No changes
- 誤った account の認証情報で `terraform plan` が `allowed_account_ids` で失敗する
- CI の plan role で app root の `terraform init` と `plan` が通る
- bucket の versioning、public access block、暗号化設定が意図どおり (`aws s3api get-bucket-versioning` 等)

## 復旧と運用

- bucket を消すと bootstrap 自身の state も消える。`prevent_destroy`、versioning、必要なら Object Lock で守る。誤削除時は versioning の旧バージョンから state を戻す
- bootstrap root の変更 (CI role の policy 追加を含む) は人が plan / apply する。頻度が上がるなら、role の policy を app の構成変更に追従させない粒度 (PowerUser + IAM 制限など) に見直す
- backend 設定の変更 (bucket 名、key) は `init -migrate-state` を再実行する

## 既存リソースの取り込み (新規環境では使わない)

手作業で作った bucket や role が既にある環境では、新規作成すると名前衝突で失敗する。`import` ブロック (Terraform 1.5+) か `terraform import` で取り込み、plan の差分 (暗号化方式、bucket policy など) をコードに合わせてから手順 4 以降を行う。変更に再作成を伴う属性 (Object Lock の無効化など) は、再作成するか対象外にするかを決める。

## 他の方式との比較

| 方式 | やり方 | 鶏卵の扱い | 選ぶ場面 |
|---|---|---|---|
| 2 段階 (本資料) | local state で apply → `init -migrate-state` | 最初の 1 回だけ local。以後は完全にコード管理 | 素の Terraform。既定 |
| ツールが肩代わり | Terragrunt の `remote_state` が bucket 不在時に AWS SDK で作成 | bucket は Terraform state 管理外 | Terragrunt を既に使っている |
| 外で作って import | CLI や CloudFormation で作成し、後から import | 手作業が残り、コードは後追い | 既存の手作業リソースがある環境だけ |
| マネージド backend | HCP Terraform 等を backend にする | 鶏卵が消える | SaaS を使える組織 |
| アカウント発行時に用意 | Control Tower AFT などで state bucket と OIDC provider を作成済みで渡す | 鶏卵を管理アカウントに 1 回だけ押し上げる | 複数アカウントを継続的に作る組織。可能なら bootstrap root から backend 作成を外す |

## 参照

- [HashiCorp: Backend Configuration](https://developer.hashicorp.com/terraform/language/backend): backend 変更時の state 移行と、移行前の state 退避
- [HashiCorp: terraform init](https://developer.hashicorp.com/terraform/cli/commands/init): `-migrate-state`、`-force-copy`、`-reconfigure` の違い
- [HashiCorp: S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3): bucket の事前作成、`use_lockfile`、DynamoDB ロックの非推奨
- [Terragrunt: State Backend](https://docs.terragrunt.com/features/state-backend): bucket の自動作成と state 管理外である注意
- [cloudposse/terraform-aws-tfstate-backend](https://github.com/cloudposse/terraform-aws-tfstate-backend): 2 段階手順と backend.tf 生成の実装例
