# AI-Driven Development Workflow

AI ツールを活用した開発ワークフローの実践ガイド。

## 概要

開発ライフサイクル全体で AI を活用:
**Issue → Implement → Review → Commit → PR**

## 主要コマンド

### Issue 管理

| コマンド | 用途 |
|---------|---------|
| `/read-issue 123` | Issue の詳細を取得・表示 |
| `/create-issue` | 新規 GitHub Issue を作成 |

### 開発

| コマンド | 用途 |
|---------|---------|
| `/review-pr 123` | PR をレビュー |
| `/review-renovate` | Renovate PR をレビュー・マージ |

### Git 操作

| コマンド | 用途 |
|---------|---------|
| `/commit` | AI 生成メッセージでコミット |
| `/commit-and-push` | コミットしてプッシュ |
| `/commit-and-pr` | コミット、プッシュ、PR 作成 |

## 典型的なワークフロー

### 1. Issue から開始

```bash
# Issue を理解する
/read-issue 42
```

### 2. 実装

```bash
# AI と反復的に協働
# - アプローチを議論
# - 生成コードをレビュー
# - 変更を依頼
```

### 3. レビュー & コミット

```bash
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

## ベストプラクティス

1. **コンテキストから始める** - 大きなタスクの前に `git status` と関連差分を確認
2. **反復** - 小さくレビュー可能な単位で作業
3. **検証** - コミット前に必ずテスト実行
4. **シンプルに** - ボイラープレートは AI に任せ、ロジックに集中

## エージェント

専門タスク用のカスタムエージェント:

- `code-reviewer` - 自動コードレビュー
- `debugger` - デバッグ支援
