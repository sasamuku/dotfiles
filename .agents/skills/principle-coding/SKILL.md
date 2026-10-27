---
name: principle-coding
description: 設計・コード・テスト・変更の進め方で判断に迷ったときに参照する、名前で通じる原則の一覧と、原則どうしがぶつかったときの優先順位。コードやテストを書くとき、レビューするときに使う。
disable-model-invocation: false
---

# Coding

原則は名前と要点だけで並べ、中身は名前から思い出す。原則どうしがぶつかったときは、「ぶつかったときの優先順位」に従う。

## 設計

| 原則 | 要点 |
|---|---|
| Single Responsibility Principle | モジュールが変更される理由を 1 つにする |
| Separation of Concerns | 関心事ごとに分ける |
| Information Hiding (Parnas) | 変わりやすい設計判断を、モジュールの内側に隠す |
| High Cohesion, Low Coupling | 一緒に変わるものを集め、別々に変わるものを離す |
| Composition over Inheritance | 継承より組み合わせで再利用する |
| Make Illegal States Unrepresentable | 起きてはいけない状態を、型で作れなくする |
| Principle of Least Astonishment | 名前から読み手が予想するとおりに振る舞わせる |
| Principle of Least Privilege | 権限は、必要最小限だけ与える |

## コード

| 原則 | 要点 |
|---|---|
| KISS | 単純な方を選ぶ |
| YAGNI | 今要らないものは作らない |
| DRY | 同じ知識を 2 か所に書かない。見た目が似ているだけのコードは対象外 |
| Rule of Three | 共通化は、同じものが 3 回現れてからにする |
| The Wrong Abstraction (Sandi Metz) | 間違った抽象化より、重複の方が安くつく |
| Fail Fast | 不正な状態を見つけたら、その場で処理を止める |
| Parse, Don't Validate | 外から来た入力は、検証して終わりにせず、検証済みであることを表す型に変換して渡す |
| Command-Query Separation | 状態を変える処理と、値を返す処理を分ける |

## テスト

| 原則 | 要点 |
|---|---|
| Arrange-Act-Assert (Given-When-Then) | 準備、実行、確認の 3 段に分けて書く |
| One Behavior per Test | 1 つのテストで、1 つの振る舞いを確かめる |
| Test Behavior, Not Implementation | 内部の実装ではなく、外から見える振る舞いを確かめる |
| F.I.R.S.T. | 速く動き、互いに独立し、何度でも同じ結果を出し、テスト自身が合否を判定する。テストは本番コードの直前に書く |
| DAMP over DRY | テストでは、共通化より読みやすさを優先する |
| Don't Mock What You Don't Own | 自分が所有していない外部の型は、直接モックせず、自分のアダプターを挟んでそれをモックする |

## 変更の進め方

| 原則 | 要点 |
|---|---|
| Make the Change Easy, Then Make the Easy Change (Kent Beck) | 変更しにくいなら、まず変更しやすい形に整え、それから変える |
| Two Hats (Kent Beck, Martin Fowler) | リファクタリングと振る舞いの変更を、同じコミットに混ぜない |

## ぶつかったときの優先順位

- 原則に沿わせる変更が依頼の範囲を超えるなら、依頼の範囲を優先し、その変更は提案に留める。
- 起きてはいけない状態を型で作れなくすることは、YAGNI より優先する。コストが小さく、防げるのはバグだからである。
- 振る舞いの抽象化 (interface、層、共通化) は、同じ形のバリエーションが 3 つ現れるまで待つ。
- テストでは、DRY より DAMP を優先する。

## 載せる基準

原則を足すときは、次をすべて満たすものだけにする。

- 名前を言えば、説明なしで通じる。
- どのプロジェクトにも当てはまり、例外を探すのが難しい。
- 既にある行の言い換えではない。
