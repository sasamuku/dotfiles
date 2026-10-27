---
name: principle-aws-architecture
description: AWS で構成を設計、レビューするときの原則。Well-Architected Framework を土台に、復旧の目標と DR、アカウントの分け方、ネットワーク、ID と権限、データの保護、記録と検知、後から変えられない決定を扱う。
metadata:
  source: https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html
disable-model-invocation: true
---

# AWS architecture

AWS の構成は、Well-Architected Framework の 6 本の柱 (運用上の優秀性、セキュリティ、信頼性、パフォーマンス効率、コスト最適化、持続可能性) で評価する。柱どうしはトレードオフの関係にあり、どれを取るかは業務の文脈で決める。ただし、セキュリティと運用上の優秀性は、原則としてほかの柱と引き換えにしない。

括弧内は Well-Architected のベストプラクティスの番号である。個々のサービスの仕様や既定値は変わるので、ここには書かない。使うときに公式ドキュメントで確かめる。

## 原則

### 復旧

- **復旧の目標を先に決める (REL13-BP01)**: 止まってよい時間 (RTO) と、失ってよいデータの量 (RPO) を、業務の要件から決める。決まっていなければ、仮の値と理由を書いて確認を取る。
- **目標に合う DR の方式を選ぶ (REL13-BP02)**: Backup and restore、Pilot light、Warm standby、Multi-site active/active の順に、RTO と RPO が短くなり、コストと複雑さが増す。要件を超える方式は選ばない。
- **複数の場所に置く (REL10-BP01)**: 本番は複数の AZ に分ける。1 つの場所にしか置けないものは、復旧を自動化する (REL10-BP02)。
- **障害の最中に作ることに頼らない (REL11-BP04、REL11-BP05)**: 切り替えはデータプレーンの操作で行い、コントロールプレーンの API に頼らない。重要なワークロードには、1 つの場所を失っても足りる容量を平時から持たせる。どこまで持つかは、コストと事業の価値を比べて決める。
- **バックアップを持ち、戻せることを試す (REL09-BP01〜04、REL13-BP03)**: レプリケーションは、破損や誤った削除も複製するので、バックアップの代わりにならない。バックアップは暗号化し、元のアカウントやリージョンが失われても戻せる場所にも置く。リストアと DR の切り替えは、定期的に試す。

### アカウント

- **ワークロードをアカウントで分ける (SEC01-BP01)**: アカウントは、セキュリティ、権限、請求、クォータの境界になる。本番と非本番を分ける。本番のアカウントには、1 つのプロダクトか、密接に関連する少数のワークロードだけを置く。責任者が違うワークロードは、別のアカウントにする。
- **管理アカウントにワークロードを置かない**: 管理アカウントは組織全体の特権を持ち、SCP がかからない。使う人とリソースを最小に絞り、組織と連携するサービスは委任管理者のアカウントから操作する。
- **統制は OU にかける**: OU は、組織図ではなく、機能、コンプライアンスの要件、共通の統制で分け、階層は浅く保つ。小さく始め、必要になったら推奨の OU とアカウントから足す。
- **root ユーザーを守る (SEC01-BP02)**: 日常の作業に使わず、MFA を付ける。

### ネットワーク

- **IP 範囲を重ねない (REL02-BP03、REL02-BP05)**: つながる可能性のあるネットワークどうしで範囲を重ねない。将来の拡張と、AZ の障害で増える分を見込んで割り当てる。多くのネットワークをつなぐなら、網の目ではなくハブアンドスポークにする (REL02-BP04)。
- **層に分け、通信を必要なものに絞る (SEC05-BP01、SEC05-BP02)**: 外に開くのは入口だけにし、データストアや内部のサービスは外から届かない層に置く。層の間も、必要な通信だけを許す。

### ID と権限

- **人はフェデレーションで入り、一時的な認証情報を使う (SEC02-BP02、SEC02-BP04)**: 人は中央の IdP から入り、ワークロードはロールを使う。長期のアクセスキーは、ほかに手段が無いときだけにする。人の認証には MFA を必須にする (SEC02-BP01)。
- **シークレットを安全に保管する (SEC02-BP03)**: コードや設定に直接書かず、Secrets Manager に置いてローテーションする。
- **最小権限で与え、減らし続ける (SEC03-BP02、SEC03-BP04)**: 外部への公開と、アカウントをまたぐアクセスを分析する (SEC03-BP07)。
- **ガードレールを組織で決める (SEC03-BP05)**: どのアカウントでも越えられない上限を、SCP などで OU に置く。
- **緊急用の入口を用意する (SEC03-BP03)**: IdP が止まったときに入れる経路を用意する。使われたら通知し、使えることを定期的に試す。
- **AWS のサービスや他社に渡す権限は、相手を条件で絞る**: サービスに許可を与えるリソースポリシーには `aws:SourceArn` や `aws:SourceAccount` を、他社に引き受けさせるロールには ExternalId を条件に付ける (混乱した代理問題)。

### データ

- **機密度で分類し、それに合わせて守る (SEC07-BP01、SEC07-BP02)**: 機密データを置くアカウントと、触れられる人を絞る。
- **暗号化を強制する (SEC08-BP02、SEC09-BP02)**: 保存時は暗号化する。転送時は、少なくとも VPC の外へ出る通信を暗号化する。
- **人をデータから遠ざける**: 直接のアクセスや手作業を、仕組みで減らす。

### 記録と検知

- **ログを決まった場所に集め、改ざんから守る (SEC04-BP01、SEC04-BP02)**: 監査ログ (CloudTrail) を全アカウント、全リージョンで取り、ログ専用のアカウントに集める。改ざんと削除から守り、記録を止められる人を絞る。
- **脅威を検知する**: GuardDuty を、使っていないリージョンも含めて有効にし、通知先と担当を決める。

### 運用とコスト

- **変更はコードで、小さく戻せる単位で行う (OPS05-BP01、OPS05-BP09)**: 手作業の変更は、レビューも再現もできず、DR で作り直すときに抜け落ちる。
- **コストの持ち主が分かるようにする (COST02-BP03、COST03-BP02)**: アカウントとタグで、どのプロダクトのコストかを割り当てる。

## 後から変えられない決定

作り直しやデータの移し替えが要るので、設計の最初に洗い出し、確認を取ってから決める。

- 組織の管理アカウント
- Control Tower のホームリージョンと、IAM Identity Center のリージョン
- VPC のプライマリ CIDR
- 作成時にしか有効にできない暗号化と鍵 (RDS など)
- 保持期間を固定するロック (S3 Object Lock と AWS Backup Vault Lock のコンプライアンスモード) と、KMS の鍵の削除

## 適用範囲と例外

AWS の構成を新しく設計するとき、既存の構成を見直すときに当てはまる。Terraform での書き方は principle-terraform に従う。個々のサービスの選び方、料金の購入オプション、アプリ側の耐障害性は扱わない。

- PoC や利用者のいない環境では、コストのために、信頼性のための構成 (複数の AZ など) を省いてよい。セキュリティは省かない。後から変えられない決定は、PoC でも先に決める。
- 障害対応で急ぐときは、手作業で直してよい。直した内容は、後でコードに戻す。

## 出典

- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html) (柱、トレードオフ、ベストプラクティスの番号)
- [Disaster recovery options in the cloud](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html) (DR の方式)
- [Design principles for your multi-account strategy](https://docs.aws.amazon.com/whitepapers/latest/organizing-your-aws-environment/design-principles-for-your-multi-account-strategy.html) (管理アカウント、本番の分け方、OU、緊急用の入口)
- [Security OU – Log Archive account](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/log-archive.html) (ログの集約)
- [The confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html)
- [GuardDuty Regions](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_regions.html)
- 後から変えられない決定: [Organizations の用語](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_getting-started_concepts.html)、[Control Tower の設定](https://docs.aws.amazon.com/controltower/latest/userguide/getting-started-configure.html)、[Identity Center の有効化](https://docs.aws.amazon.com/singlesignon/latest/userguide/get-started-enable-identity-center.html)、[VPC の CIDR](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)、[RDS の暗号化](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.html)、[S3 Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)、[Vault Lock](https://docs.aws.amazon.com/aws-backup/latest/devguide/vault-lock.html)、[KMS の鍵の削除](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html)
