# Sentry

Sentry の SDK と担当の割り当てを設定するときの観点を置く。Sentry はアプリケーションのエラーとトレースを見る。インフラの指標は別の監視で見る。共通の原則は SKILL.md にあり、ここには Sentry に固有の観点だけを置く。

SDK の設定はコードにあるが、担当の割り当ては Sentry 側の設定にある。コードだけを見ても、担当の割り当ては確かめられない。

## 判断の観点

### 送るもの

- **環境とリリースを付ける**: イベントに環境とリリースを付ける。環境を条件にしてアラートを出せるようになり、リリースで新しく出たエラーと再発を見分けられる。実行の形が違うもの (API、ワーカー、バッチ) は、区別できるように分ける。
- **ノイズは SDK で落とす**: 対応しないと決めたエラーは、送る前に SDK で落とす。Sentry は、不要なイベントを送る負荷が無くなることを理由に、SDK での絞り込みを勧めている。落としたイベントは後から見られないので、条件は狭く書き、落とす理由を残す。
- **エラーは全件を送る**: エラーのサンプリング率は既定で全件である。下げると、まれなエラーが見えなくなる。量が問題になる経路だけを個別に絞る。
- **トレースは低い率から始める**: トレースはスパンの数で課金される。本番で全件を送ると、トラフィックに比例して費用が増える。率は、月に使ってよいスパン数を、リクエスト数と 1 トレースあたりのスパン数で割って決める。分からないうちは 1% のような低い率から始め、量を見て上げる。開発や検証の環境は、量が少ないので高い率でよい。経路ごとに率を変えるなら、サンプラーの関数を使う。
- **トレースの判定は親から引き継ぐ**: サービスごとに判定を変えると、トレースが途中で切れる。
- **サンプリングと、送る直前の間引きを重ねない**: サンプリング率で選んだあとに、送る直前のフックでさらに間引くと、実際の率は掛け算になる。トレースも一部だけが欠ける。
- **短命なプロセスは、終了の前に送り切る**: イベントは送信を待つ列に入る。バッチのようにすぐ終わるプロセスは、終了の前に `flush` か `close` で列を空にする。

### 秘密情報

- **SDK で取り除く**: SDK のフックで取り除けば、秘密情報は手元の環境から出ない。Sentry 側での除去は設定をすぐ変えられる利点があるが、データは一度 Sentry に届く。手元に Relay を置くと、Sentry に届く前に取り除きつつ、再デプロイせずに設定を変えられる。
- **自動で集まるものを確かめる**: URL のクエリ文字列は、リクエスト、パンくず (breadcrumb)、スパンのそれぞれに入る。ユーザーの情報と、スタックのローカル変数にも、意図せず秘密情報が入る。ローカル変数を集めるかどうかは SDK によって違う。
- **利用者は内部の ID で識別する**: メールアドレスの代わりに内部の ID を送れば、影響を受けた利用者の数は分かる。

### 担当の割り当て

- **担当の割り当てに ownership rules を使う**: ownership rules はファイルのパス、URL、タグで Issue を担当に割り当てる。CODEOWNERS の取り込みは使えるプランが限られ、コードの対応付けの設定が先に要る。

## 出典

- [Environments](https://docs.sentry.io/concepts/key-terms/environments/)
- [Releases](https://docs.sentry.io/product/releases/)
- [Filtering](https://docs.sentry.io/platforms/javascript/configuration/filtering/)
- [Sampling](https://docs.sentry.io/platforms/javascript/configuration/sampling/)
- [Pricing](https://docs.sentry.io/pricing/) (スパンの数での課金)
- [Shutdown and Draining](https://docs.sentry.io/platforms/javascript/guides/node/configuration/draining/)
- [Scrubbing Sensitive Data](https://docs.sentry.io/platforms/javascript/data-management/sensitive-data/)
- [Ownership Rules](https://docs.sentry.io/product/issues/ownership-rules/)

SDK の資料は JavaScript 版を参照した。オプションの名前と既定値は、使う SDK の資料で確かめる。サンプリングと間引きを重ねないことと、開発や検証の環境で率を高くすることは、出典に無い設計判断である。
