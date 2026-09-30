---
name: review-renovate
description: Review Renovate dependency updates, fix CI failures, and merge verified PRs.
disable-model-invocation: true
---

# Review Renovate

対象: $ARGUMENTS。未指定なら `gh pr list --author=app/renovate --state open` で一覧を取得する。

1. `gh pr view <N>` と `gh pr checks <N>` で変更・CIを確認する。
2. リリースノート・CHANGELOG・peer依存の互換性を確認する。patchは簡易、minorは新機能、majorは破壊的変更を重点的に見る。セキュリティ更新を優先する。
3. CI失敗は対象PRをチェックアウトして原因・コンフリクトを確認し、リポジトリに実在するinstall・test・build・lintコマンドで検証する。必要な修正をpushする。
4. 必須CIが完了・成功し、互換性と変更内容を確認できたPRを `gh pr review --approve <N>` → `gh pr merge <N>` で承認・マージする。pending・失敗・未確認の問題は完了扱いせず報告する。
