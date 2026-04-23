---
name: review-code
description: Review local code changes against main branch
disable-model-invocation: true
---

# Review Code

現在のブランチと main の差分 (未コミット・コミット済みの変更すべて) をレビューする。

## 手順

1. main と現在の HEAD の差分を取得する:
   ```bash
   git diff main...HEAD
   ```

2. コンテキスト用のコミット履歴を取得する:
   ```bash
   git log main..HEAD --oneline
   ```

3. 未コミットの変更がある場合:
   ```bash
   git diff
   git diff --cached
   ```

4. **code-reviewer** エージェントでレビューを実施する

## 出力

code-reviewer エージェントが優先度別に構造化されたフィードバックを提供する:
- **Critical**: セキュリティ問題、バグ
- **Warning**: コード品質の懸念事項
- **Suggestion**: 改善提案

ファイルパスと修正の推奨事項を含む。
