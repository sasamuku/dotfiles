# AI-Driven Development Workflow

AI ツールを活用した開発ワークフローの実践ガイド。

## 概要

開発ライフサイクル全体で AI を活用:
**Issue → Plan → Implement → Review → Commit → PR**

## 主要コマンド

### Issue 管理

| コマンド | 用途 |
|---------|---------|
| `/read-issue 123` | Issue の詳細を取得・表示 |
| `/fix-issue 123` | Issue を分析し、修正を実装、テスト実行 |
| `/create-issue` | 新規 GitHub Issue を作成 |
| `/create-sub-issue` | 親 Issue にリンクした子 Issue を作成 |

### 計画

| コマンド | 用途 |
|---------|---------|
| `/create-plan #123` | Issue から PLANS.md を生成 |
| `/sync-plan` | PLANS.md を Issue コメントに同期 |
| `/update-plan-from-subissues` | 子 Issue のステータスで計画を更新 |
| `/summarize-epic` | Epic Issue の進捗をサマリ表示 |

### 開発

| コマンド | 用途 |
|---------|---------|
| `/understand-context` | プロジェクトのコンテキストを把握 |
| `/review-pr 123` | PR をレビュー |
| `/review-renovate` | Renovate PR をレビュー・マージ |

### Git 操作

| コマンド | 用途 |
|---------|---------|
| `/commit` | AI 生成メッセージでコミット |
| `/commit-and-push` | コミットしてプッシュ |
| `/commit-and-pr` | コミット、プッシュ、PR 作成 |
| `/squash-commits` | コミットを適切に整理 |
| `/stash-and-rebase` | スタッシュ、main にリベース、再適用 |

## 典型的なワークフロー

### 1. Issue から開始

```bash
# Issue を理解する
/read-issue 42

# 実行計画を作成
/create-plan #42
```

### 2. 実装

```bash
# AI に修正を実装させる
/fix-issue 42

# または反復的に AI と協働
# - アプローチを議論
# - 生成コードをレビュー
# - 変更を依頼
```

### 3. レビュー & コミット

```bash
# コミットを論理的に整理
/squash-commits

# 説明的なメッセージでコミット
/commit-and-push
```

### 4. PR 作成

```bash
# AI 生成の説明で PR 作成
/commit-and-pr
```

## MCP サーバー

Model Context Protocol による機能拡張:

- **playwright** - テスト用ブラウザ自動化
- **context7** - 最新ライブラリドキュメント
- **serena** - セマンティックコードナビゲーション

## ベストプラクティス

1. **コンテキストから始める** - 大きなタスクの前に `/understand-context`
2. **先に計画** - 複雑な機能は `/create-plan` を使用
3. **反復** - 小さくレビュー可能な単位で作業
4. **検証** - コミット前に必ずテスト実行
5. **シンプルに** - ボイラープレートは AI に任せ、ロジックに集中

## エージェント

専門タスク用のカスタムエージェント:

- `code-reviewer` - 自動コードレビュー
- `debugger` - デバッグ支援
- `plan-driven-coder` - PLANS.md に基づく実装
