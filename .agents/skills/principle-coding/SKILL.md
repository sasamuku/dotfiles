---
name: principle-coding
description: 設計・コード・テスト・変更の進め方で判断に迷ったときに参照する、名前で通じる原則の一覧と、原則どうしがぶつかったときの優先順位。コードやテストを書くとき、レビューするときに使う。
disable-model-invocation: false
---

# Coding

判断に迷ったときに参照する原則を、名前と要点だけで並べる。中身は名前から思い出す。

## 設計

| 原則 | 要点 |
|---|---|
| Single Responsibility Principle | 変更する理由が 1 つになるように分ける |
| Separation of Concerns | 関心ごとに分ける |
| Information Hiding (Parnas) | 変わりやすい判断を、モジュールの内側に隠す |
| High Cohesion, Low Coupling | 一緒に変わるものを集め、別に変わるものを離す |
| Composition over Inheritance | 継承より組み合わせで再利用する |
| Make Illegal States Unrepresentable | 起きてはいけない状態を、型で作れなくする |
| Principle of Least Astonishment | 名前と振る舞いを、読み手の予想に合わせる |
| Principle of Least Privilege | 権限は、必要な最小限だけ与える |

## コード

| 原則 | 要点 |
|---|---|
| KISS | 単純な方を選ぶ |
| YAGNI | 今要らないものは作らない |
| DRY | 同じ知識を 2 か所に書かない。見た目が似ているだけのコードは対象外 |
| Rule of Three | 共通化は、同じものが 3 回現れてからにする |
| The Wrong Abstraction (Sandi Metz) | 間違った抽象化より、重複の方が安い |
| Fail Fast | おかしな状態は、その場で止める |
| Parse, Don't Validate | 外から来た入力は、検証して終わりにせず、正しい型に変換して渡す |
| Command-Query Separation | 状態を変える処理と、値を返す処理を分ける |

## テスト

| 原則 | 要点 |
|---|---|
| Arrange-Act-Assert (Given-When-Then) | 準備、実行、確認の 3 段に分けて書く |
| One Behavior per Test | 1 つのテストで、1 つの振る舞いを確かめる |
| Test Behavior, Not Implementation | 内部の実装ではなく、外から見える振る舞いを確かめる |
| F.I.R.S.T. | 速く、互いに独立し、何度でも同じ結果になり、自分で合否を判定し、早く書く |
| DAMP over DRY | テストは、共通化より、読んで分かることを優先する |
| Don't Mock What You Don't Own | 自分で持たない外部の型は、直接モックせず、自分の境界を挟む |

## 変更の進め方

| 原則 | 要点 |
|---|---|
| Make the Change Easy, Then Make the Easy Change (Kent Beck) | 変更しにくいなら、先に変更しやすい形に整えてから変える |
| Two Hats (Kent Beck, Martin Fowler) | リファクタリングと振る舞いの変更を、同じコミットに混ぜない |

## ぶつかったときの優先

- 原則に沿う変更が依頼の範囲を超えるなら、範囲を優先し、その変更は提案に留める。
- 起きてはいけない状態を型で消すことは、YAGNI より優先する。コストが小さく、消えるのはバグだからである。
- 振る舞いの抽象化 (interface、層、共通化) は、同じ形のバリエーションが 3 つ目になるまで待つ。
- テストでは、DRY より DAMP を優先する。

## 載せる基準

原則を足すときは、次をすべて満たすものだけにする。

- 名前を言えば、説明なしで通じる。
- どのプロジェクトにも当てはまり、例外を探す方が難しい。
- 既にある行の言い換えではない。
