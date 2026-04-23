---
name: create-plan
description: Create a PLANS.md execution plan document for project management
disable-model-invocation: true
---

# Create Plan

プロジェクトルートに、実行計画を管理するための PLANS.md を作成する。

## 引数

受け付ける入力:
- プロジェクトの説明・文脈 (自由記述)
- GitHub Issue 番号 (例: `123` または `#123`)
- GitHub Issue の URL

$ARGUMENTS

## 入力の扱い

引数が GitHub Issue を参照している場合:
1. 引数から Issue 番号を抽出する (形式: `#123`, `123`, または GitHub URL)
2. `gh issue view <issue-number> --json number,title,body,url` で Issue を取得する
3. Issue から要件と文脈を把握する
4. 必要に応じてコードベースから関連ファイルを検索する
5. Issue の情報で PLANS.md の各セクションを埋める
6. Issue メタデータをフロントマターに追加する (後述の Frontmatter セクション参照)
7. PLANS.md 作成後、Issue に初回の sync コメントを投稿する

## Frontmatter (Issue 連携時)

Issue と紐づく PLANS.md を作る際は、以下のフロントマターを先頭に追加する:

```yaml
---
issue: 123
issue_url: https://github.com/owner/repo/issues/123
last_synced: 2025-11-12T10:30:00Z
---
```

- `issue`: Issue 番号
- `issue_url`: Issue の完全な GitHub URL
- `last_synced`: 最終同期日時 (ISO 8601)。`date -u +"%Y-%m-%dT%H:%M:%SZ"` で生成

## PLANS.md の構成

1. **Purpose / Overview**
   - プロジェクトゴールの要約
   - 中核的な価値提案
   - 解決する問題

2. **Context & Direction**
   - 問題の背景
   - 設計思想
   - 主要な制約

3. **Validation & Acceptance Criteria**
   - テスト可能な受け入れ基準
   - テストシナリオ
   - 成功指標

4. **Specification**
   - システム仕様
   - アーキテクチャ上の決定
   - 設計の詳細

5. **Open Questions**
   - 未解決の問い
   - 検討中の選択肢
   - ブロッカー・不確実性

6. **Discoveries & Insights**
   - 技術的な発見
   - 実装上の学び
   - 想定外の所見

7. **Decision Log**
   - 主要な判断 (日付付き)
   - 根拠と文脈
   - 検討したトレードオフ

8. **Outcomes & Retrospectives**
   - マイルストーンの結果
   - 学び
   - 良かった点・改善できる点

9. **Follow-up Issues**
   - 今後取り組む項目
   - 対象外としたタスク
   - 技術的負債

## ガイドライン

- 現時点で得られるプロジェクトコンテキストから着手する
- ユーザー入力を参照してプロジェクトの範囲を理解する
- 簡潔さと網羅性を両立する
- 継続的に更新される「生きたドキュメント」として整形する
- 追跡可能なタスクには Markdown チェックボックス (`- [ ]`) を使う
- **重要**: PLANS.md を作成する前にプレビューを提示し、ユーザー承認 (y/n) を得ること

## Issue コメント同期 (Issue 連携時)

Issue フロントマター付き PLANS.md を作成したら、Issue にコメントを投稿する:

1. リポジトリ情報を取得: `gh repo view --json owner,name`
2. タイムスタンプ付きの同期マーカーを生成する
3. マーカー + PLANS.md 本文 (フロントマターを除く) をコメントとして投稿する:

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$(tail -n +5 PLANS.md)"  # Skip frontmatter (lines 1-4)

gh issue comment <issue-number> --body "$CONTENT"
```

同期マーカーの形式: `<!-- PLANS_SYNC_MARKER:2025-11-12T10:30:00Z -->`

これにより、`/sync-plan` が後からこのコメントを発見・更新できるようになる。
