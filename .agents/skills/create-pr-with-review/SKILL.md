---
name: create-pr-with-review
description: Review local changes with independent specialists, fix findings, then create a PR using create-pr.
---

# Create PR with Review

## 対象の確認

- baseは `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name` で確認する。
- `git branch --show-current`、`git status --short`、`git log <base>..HEAD --oneline` を確認し、未コミット変更は先にコミットする。レビュー対象は `git diff <base>...HEAD` のコミット済み差分。
- 空差分なら終了する。PRの目的・背景を1〜3文にまとめ、不明なら確認する。

## 独立したレビュー

[review-pr](../review-pr/SKILL.md) のエージェント一覧・トリガー評価・Phase 2〜4を使う。PR差分はローカル差分に、差分内テストは本ブランチの変更行に読み替える。GitHubの情報取得・投稿は行わない。

該当reviewerを、メインセッションの履歴を継承しない独立したサブエージェントとして並列起動する。渡す情報は以下だけ:

- PRの目的・背景、base/head、コミット一覧
- 最新のdiff生出力 (ハンクヘッダ込み)
- [output-format.md](../review-pr/output-format.md) の本文

実装の試行錯誤・代替案・弁明・会話要約は渡さない。再レビューにも前回の指摘や修正経緯を渡さず、毎回新しい文脈でレビューする。

## 修正ループ (最大3ラウンド)

1. 正本の集約・最終フィルタを適用し、指摘表を提示する。指摘ゼロならPR作成へ。
2. 通過した指摘は優先度を問わず修正する。PR目的・意図的な設計と衝突する場合は勝手に棄却せずユーザーの判断を得る。
3. ユーザーが棄却した指摘は同ファイル・同根本原因で記録し、以降は集約側で修正対象から除く。reviewerには伝えない。
4. 修正をコミットし、最新差分を再レビューする。

reviewerが失敗した場合は残りの結果で続行し、未実施の観点を明記する。修正がテストを壊すなど完了できなければ中断し、状況・残指摘を報告する。
3ラウンドで収束しなければ残指摘を示し、修正続行かそのままPR作成かをユーザーに確認する。

## PR作成

[create-pr](../create-pr/SKILL.md) に従う。確認した目的をSummaryの基にし、レビュー修正の経緯は本文に含めない。
