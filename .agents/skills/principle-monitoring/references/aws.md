# AWS

CloudWatch のアラーム、EventBridge のルール、SNS の通知、AWS Health で監視を組むときの観点を置く。共通の原則は SKILL.md にあり、ここには AWS に固有の仕様と使い方だけを置く。サービスごとの指標と閾値は書かず、公式の推奨アラームを参照する。

## 判断の観点

### 何を見るか

- **推奨アラームを出発点にする**: AWS はサービスごとに推奨する指標、統計、閾値、その理由を公開している。値は出発点であり、多くは「状況による」とされている。過去のデータから自分の基準を求めて直す。
- **AWS Health のイベントを通知の経路に流す (OPS08-BP04)**: AWS 側の障害と、対応が要る予定された変更は、AWS Health に出る。データベースのエンジンや Kubernetes のバージョンのサポート終了は、ここに予告される。RDS のイベント通知には、この予告が無い。Dashboard は見に行かないと気づけないので、EventBridge のルールか AWS User Notifications で通知の経路に流す。EventBridge のルールは受け取りたいリージョンごとに作る。IAM のようなリージョンに属さないサービスのイベントは、us-east-1 のルールで受け取る。

### アラームの条件

- **欠落データの扱いを明示する**: 既定は `missing` で、評価範囲のデータがすべて無いとアラームは `INSUFFICIENT_DATA` になる。エラーのときだけ値が出る指標は `notBreaching` にする。常に値が出る指標は、途切れること自体が異常なので、`breaching` を検討する。どちらの指標かは、サービスの資料で確かめる。既定が違う名前空間もある (`AWS/DynamoDB` は `ignore`)。
- **存在しない指標のアラームも作れてしまう**: CloudWatch は指標がまだ存在しなくてもアラームを作る。ディメンションを誤るか、対象が消えると、アラームはデータの無いまま残る。`notBreaching` にしていると、そのアラームは `OK` のままになる。
- **率を計算するなら、欠落を埋める**: エラーのときだけ値が出る指標を計算式で率にすると、エラーが無い期間は率も欠落する。`FILL` で 0 を埋めてから計算する。
- **続いた回数は M out of N で指定する**: 評価期間の数 (N) と、そのうち何回超えたら鳴らすか (M) を分けて指定できる。
- **周期のある指標には、異常検知のアラームを使える (OPS08-BP04)**: 時間帯や曜日の周期を学習した幅を、閾値の代わりにする。
- **複合アラームでまとめるなら、子の通知を外す (OPS08-BP04)**: 複合アラームはほかのアラームの状態を条件にする。通知は複合アラームだけに設定し、子のアラームにはアクションを付けない。子にも通知を残すと、通知は減らない。子のアラームは複合アラームと同じアカウントとリージョンに要る。
- **イベントは異常だけに絞る**: 状態変化のイベントは正常な操作でも起きる。コンテナの停止はデプロイやスケールインでも起きる。EventBridge のルールで、異常を示す条件だけを拾う。

### 通知の経路

- **`OK` に戻ったときのアクションは別に設定する**: アラームのアクションは状態ごとに設定する。異常時のアクションを設定しただけでは、復旧は通知されない。
- **対応の手がかりはアラームの説明に書く**: アラームの説明は通知にそのまま載る。Markdown が描画されるのはコンソールだけで、通知には書いた文字のまま載る。
- **アクションの宛先は検証されない**: CloudWatch はアクションに指定した宛先が存在するかを確かめない。存在しないトピックを指定しても、アラームは作れる。`set-alarm-state` でアラームの状態を一時的に変え、通知が届くことを試す。
- **トピックは暗号化し、発行するサービスに鍵を使わせる**: AWS のサービスが発行するトピックを暗号化するには、カスタマー管理の鍵を使い、発行するサービスに `kms:GenerateDataKey*` と `kms:Decrypt` を許可する。許可が無いと、サービスはトピックに発行できない。
- **発行元を条件で絞る**: トピックと鍵のポリシーには、`aws:SourceAccount` や `aws:SourceArn` を条件に付ける (principle-aws-architecture の混乱した代理問題)。アラームの ARN に ASCII 以外の文字があるときは、`aws:SourceAccount` だけを使う。EventBridge から暗号化したトピックへ送る場合、鍵のポリシーではこれらの条件を使えない。
- **指標が出るリージョンにアラームを作る**: CloudFront の指標は us-east-1 に出るので、アラームもそこに作る。通知の経路がそのリージョンのアラームから使えるかを確かめる。

## Well-Architected との対応

SKILL.md の原則に対応する、Well-Architected のベストプラクティスの番号を置く。

| SKILL.md の原則 | 番号 |
|---|---|
| 事業の指標と結び付ける | OPS04-BP01、OPS08-BP04 |
| 監視を監視対象と一緒に止めない (外形監視) | OPS04-BP03 |
| 依存先を分けて見る | OPS04-BP04 |
| 人が動けるものだけを通知する (自動化) | REL06-BP04 |
| 閾値には根拠を残し、見直す | REL06-BP03、REL06-BP06 |
| 監視を監視対象と一緒に止めない (通知の経路) | REL06 |

## 出典

- [Recommended alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html) (サービスごとの推奨アラーム)
- [Using Amazon CloudWatch alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html) (存在しない指標のアラーム、アクションの検証、`set-alarm-state`)
- [Configuring how CloudWatch alarms treat missing data](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/alarms-and-missing-data.html)
- [Composite alarms](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/alarm-combining.html) (子のアクション、アカウントとリージョン)
- [Create a composite alarm](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html) (説明の Markdown)
- [OPS08-BP04 Create actionable alerts](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/ops_workload_observability_create_alerts.html) (異常検知、複合アラーム、AWS Health)
- [REL06-BP03 Send notifications](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/rel_monitor_aws_resources_notification_monitor.html)
- [Planned lifecycle events for AWS Health](https://docs.aws.amazon.com/health/latest/ug/aws-health-planned-lifecycle-events.html) (サポート終了の予告、受け取り方)
- [Amazon RDS event categories and event messages](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Events.Messages.html) (RDS のイベント通知)
- [Creating EventBridge rules for AWS Region coverage](https://docs.aws.amazon.com/health/latest/ug/choosing-a-region.html) (AWS Health のリージョン)
- [Managing Amazon SNS encryption keys](https://docs.aws.amazon.com/sns/latest/dg/sns-key-management.html) (暗号化したトピックと、発行するサービスの権限)
- [Notifying users on alarm changes](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Notify_Users_Alarm_Changes.html) (ポリシーの条件、通知に載る項目)
- [Types of metrics for CloudFront](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/programming-cloudwatch-metrics.html) (指標が出るリージョン)

イベントを異常だけに絞ることと、率の計算で欠落を埋めることは、出典に無い設計判断である。
