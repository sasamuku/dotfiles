# TypeScript の品質チェック・テスト

導入前に `package.json`、lockfile、Node のバージョンを確認する。

| 用途 | 選択肢 | 選ぶ条件・重複関係 |
|---|---|---|
| 依存管理 | pnpm / npm / Yarn | 既存を維持。新規はユーザー指定を優先し、未指定なら pnpm |
| 型検査 | TypeScript（tsc） | framework の型生成が必要なら既存の typecheck 経路を使う |
| lint・整形 | Biome | lint・整形は Biome に統一。既存の別ツールからの移行が必要なら、その差分を示して選択を受け取る |
| 未使用コード・依存 | Knip | entry・workspace・生成物を対象 PJ に合わせる |
| ユニット・結合テスト | Vitest | Node / DOM / Workers 等の実行環境に合わせる |

- 依存は対象 workspace の適切な場所に追加し、lockfile を更新する。lint / format / typecheck / test 等は既存の命名を優先し、CI とローカルで同じ scripts を呼ぶ。

- 型生成が必要なチェックは生成後に実行する。生成物・build 出力を lint や未使用検査へ誤って含めない。

- テスト基盤を選んだ場合は PJ の実際の機能に対する最小のテストを実行する。機能がまだなければ基盤・test script だけ導入し、CI のテストステップは最初の実テスト追加まで保留と報告する。ダミーテストや `passWithNoTests` で成功扱いにしない。

## 公式資料

- [Biome](https://biomejs.dev/guides/getting-started/)
- [Vitest](https://vitest.dev/guide/)
