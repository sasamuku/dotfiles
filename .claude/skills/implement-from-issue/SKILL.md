---
name: implement-from-issue
description: End-to-end workflow from GitHub issue to reviewed code. Reads issue, creates plan, implements code, and iterates review-fix cycles until quality passes.
disable-model-invocation: true
argument-hint: [issue-number]
---

# Issue からの実装

GitHub Issue からレビュー済みコードまでのライフサイクルを自動化する (GitHub Issue → 計画 → 実装 → レビュー)。

## 引数

Issue 番号 (例: `123` または `#123`) または GitHub Issue の URL。

$ARGUMENTS

## ワークフロー

### フェーズ 1: Issue から計画を作成する

引数の Issue 番号を使って `@.claude/skills/plan-from-issue/SKILL.md` に従う。

### フェーズ 2: 計画を実装する

`@.claude/skills/implement-from-plan/SKILL.md` に従い、PLANS.md の全項目を実装する。

### フェーズ 3: 変更をコミットする

`-y` オプションを付けて `@.claude/skills/commit/SKILL.md` に従い、コミットを自動承認する。

### フェーズ 4: レビューと修正のループ

以下のサイクルを最大 3 回繰り返す:

1. `@.claude/skills/review-code/SKILL.md` に従い、すべての変更をレビューする
2. **Critical** または **Warning** の問題が見つかった場合:
   - 問題を修正する
   - `-y` オプションを付けて `@.claude/skills/commit/SKILL.md` に従い、修正をコミットする
   - 次のイテレーションへ進む
3. Critical/Warning の問題がなくなればループを抜ける

### 完了

サマリーを出力する:
```
Done: Issue #<number> implemented and reviewed.
Review cycles: <count>
```
