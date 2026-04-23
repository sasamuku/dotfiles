---
name: create-issue
description: General guidelines for creating GitHub issues
disable-model-invocation: true
---

# Create Issue

GitHub CLI を使って新規 Issue を作成する。

## 引数

$ARGUMENTS

例:
- `Add dark mode support` - この説明で Issue を作成
- `Bug: login fails on Safari` - バグレポートを作成
- (空) - 会話の文脈から推測し、Issue を提案

## プロセス

### 1. Issue テンプレートの有無を確認する

`.github/ISSUE_TEMPLATE` ディレクトリを探す。
テンプレートがあれば、最も適切なものを利用する。

### 2. 依頼内容を分析する

文脈と技術的な影響を把握する:
- 現状と目指す状態
- 技術要件と依存関係
- 取りうる実装アプローチ
- 影響とリスク

### 3. Issue をドラフトする

- **タイトル**: 明確で説明的 (Conventional Commits 形式は **使わない**)
- **本文**: 次の構成で記述する:
  - Overview (問題のサマリ)
  - Current state
  - Investigation results
  - Action items
  - Impact analysis
  - Technical considerations

### 4. ユーザー承認を得る

```
Issue Draft:

Title: [proposed title]

Body:
[complete issue body]

Do you approve this issue? (y/n)
```

**作成前にユーザー承認を待つこと。**

### 5. Issue を作成する

```bash
gh issue create --title "Title" --body "Body"
```

## ベストプラクティス

- 根拠に具体的なファイルパスや行番号を含める
- Markdown 記法を利用する
- タイトルは簡潔かつ分かりやすく
