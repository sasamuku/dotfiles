---
name: review-renovate
description: Review and merge renovate PRs with automerge configuration updates
disable-model-invocation: true
---

# Review Renovate

構造化されたワークフローに従い、Renovate PR をレビューしてマージする。

## 引数

$ARGUMENTS

## ワークフロー

1. **オープンな Renovate PR を一覧表示する**:
   ```bash
   gh pr list --author=app/renovate --state open
   ```

2. **各 PR の詳細を確認する**:
   ```bash
   gh pr view <number>
   gh pr checks <number>
   ```

3. **CI が失敗している場合**:
   - チェックアウト: `gh pr checkout <number>`
   - コンフリクトを確認し、必要に応じて解消する
   - 実行: `pnpm install && pnpm test && pnpm build && pnpm lint`
   - 問題を修正してプッシュする

4. **バージョン変更のリスクを評価する**:
   - **patch**: リスク低 — 簡易レビュー
   - **minor**: リスク中 — 新機能の確認
   - **major**: リスク高 — 詳細なレビューが必要

5. **CHANGELOG / リリースノートを確認する**

6. **ピア依存関係の互換性を確認する**

7. **承認してマージする**:
   ```bash
   gh pr review --approve <number>
   gh pr merge <number>
   ```

## レビュー基準

- **セキュリティアップデート**: 常に最優先で対応する
- **Patch アップデート**: リスク低 — 簡易レビュー
- **Minor アップデート**: リスク中 — 新機能の確認
- **Major アップデート**: リスク高 — 詳細なレビューが必要
