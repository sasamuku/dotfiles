---
name: sync-plan
description: Sync PLANS.md content to linked GitHub issue comment. Use when PLANS.md is updated and changes need to be reflected in the GitHub issue.
disable-model-invocation: true
---

# Sync Plan

PLANS.md の内容を、連携済みの GitHub Issue コメントに同期する。

## 前提条件

- プロジェクトルートに PLANS.md が存在すること
- PLANS.md のフロントマターに `issue:` フィールドが含まれていること

## ワークフロー

### 1. PLANS.md から Issue メタデータを読み取る

フロントマターから `issue:` と `issue_url:` を抽出する。

`issue:` フィールドが存在しない場合:
```
Error: No issue linked to PLANS.md
Create an issue-linked plan with: /create-plan <issue-number>
```

### 2. リポジトリ情報を取得する

```bash
gh repo view --json owner,name
```

### 3. 既存の同期コメントを検索する

```bash
gh api repos/{owner}/{name}/issues/{issue}/comments \
  --jq '.[] | select(.body | contains("PLANS_SYNC_MARKER")) | .id'
```

### 4. コメントを更新または作成する

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$(tail -n +5 PLANS.md)"
```

**コメントが既に存在する場合**:
```bash
gh api -X PATCH repos/{owner}/{name}/issues/comments/{comment_id} \
  -f body="$CONTENT"
```

**コメントが存在しない場合**:
```bash
gh issue comment {issue} --body "$CONTENT"
```

### 5. PLANS.md のフロントマターを更新する

`last_synced` フィールドを新しいタイムスタンプで更新する。

### 6. 完了を確認する

```
✓ Synced PLANS.md to issue #123
  Timestamp: 2025-11-12T10:30:00Z
```

## 注意事項

- 同期は一方向: PLANS.md → GitHub Issue
- GitHub コメントを手動編集した場合、次の同期で上書きされる
