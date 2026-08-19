---
name: create-plan
description: End-to-end workflow that reads a GitHub issue (with epic/sibling/PR context), creates an execution plan file under ~/.claude/plans/, and syncs it back to the issue comment.
---

# Create Plan

GitHub Issue を読み込み、実行計画ファイルを作成し、Issue に同期する — これらを 1 ステップで実行する。

## 計画ファイルの置き場所 (規約)

```
~/.claude/plans/<owner>/<repo>/issue-<issue-number>.md
```

- リポジトリの外に置くため git と無縁 (コンフリクト・コミット混入が起きない)
- 絶対パスなので worktree・セッションをまたいで同じファイルを参照できる
- 正本は Issue の同期コメント (PLANS_SYNC_MARKER)。ローカルファイルは作業コピー

パス解決:

```bash
REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')
PLAN_FILE="$HOME/.claude/plans/$REPO/issue-<issue-number>.md"
mkdir -p "$(dirname "$PLAN_FILE")"
```

## 引数

GitHub Issue 番号 (例: `123` または `#123`) または Issue の URL。

$ARGUMENTS

**Issue は必須**。引数に Issue の参照がない場合 (自由記述のみ等) は計画ファイルを作らず、次を案内する:

```
計画は Issue に紐づけて管理します。先に Issue を作成してください:
  /create-issue <タイトル・概要>
作成後、/create-plan <issue-number> で計画を作成できます。
```

ユーザーが望めば、その場で `/create-issue` スキルのワークフローに従って Issue を作成し、続けて計画作成に進んでよい。

## ワークフロー

### フェーズ 1: Issue の読み込み

引数の Issue 番号を使い、`/read-issue` スキルのワークフローに従う (親 Epic・兄弟 Issue・実装 PR まで含めた文脈収集)。

### フェーズ 2: 計画ファイルの作成

1. フェーズ 1 で収集した情報から要件と文脈を把握する
2. 必要に応じてコードベースから関連ファイルを検索する
3. 計画ファイルの各セクションを埋め、フロントマターを付ける (後述)
4. **重要**: 計画ファイルを作成する前にプレビューを提示し、ユーザー承認 (y/n) を得ること

### フェーズ 3: Issue への同期

`/sync-plan` スキルのワークフローに従い、計画を Issue に投稿する。

完了したら以下を表示する:
```
Done: Issue #<number> read, plan created at ~/.claude/plans/<owner>/<repo>/issue-<number>.md, synced to issue.
```

## Frontmatter

計画ファイルの先頭に、以下のフロントマターを必ず付ける:

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

## 計画ファイルの構成

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
