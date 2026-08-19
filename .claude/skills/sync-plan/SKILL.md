---
name: sync-plan
description: Sync the plan file (~/.claude/plans/) to the linked GitHub issue comment. Use when the plan is updated and changes need to be reflected in the GitHub issue.
disable-model-invocation: true
---

# Sync Plan

計画ファイルの内容を、連携済みの GitHub Issue コメントに同期する。

## 引数

$ARGUMENTS

## ワークフロー

### 1. 計画ファイルを特定する

```bash
REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')
PLAN_DIR="$HOME/.claude/plans/$REPO"
```

- 引数に Issue 番号があれば `$PLAN_DIR/issue-<n>.md`
- なければ `ls -t "$PLAN_DIR"` の最新ファイル。候補が複数あって文脈から特定できない場合はユーザーに確認する

計画ファイルが存在しない場合:
```
Error: No plan found for this repository
Create one with: /create-plan <issue-number>
```

### 2. フロントマターから Issue メタデータを読み取る

`issue:` と `issue_url:` を抽出する。

### 3. 既存の同期コメントを検索する

```bash
gh api repos/{owner}/{name}/issues/{issue}/comments \
  --jq '.[] | select(.body | contains("PLANS_SYNC_MARKER")) | .id'
```

### 4. コメントを更新または作成する

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$(tail -n +6 "$PLAN_FILE")"  # フロントマター (5 行) をスキップ
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

### 5. 計画ファイルのフロントマターを更新する

`last_synced` フィールドを新しいタイムスタンプで更新する。

### 6. 完了を確認する

```
✓ Synced plan to issue #123
  File: ~/.claude/plans/{owner}/{repo}/issue-123.md
  Timestamp: 2025-11-12T10:30:00Z
```

## 注意事項

- 同期は一方向: 計画ファイル → GitHub Issue
- GitHub コメントを手動編集した場合、次の同期で上書きされる
