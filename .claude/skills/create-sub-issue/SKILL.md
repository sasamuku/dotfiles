---
name: create-sub-issue
description: Create a sub-issue linked to a parent GitHub issue
disable-model-invocation: true
---

# サブ Issue の作成

サブ Issue API を使って、親 GitHub Issue に紐づくサブ Issue を作成する。

## 引数

- 親 Issue 番号 (例: `123` または `#123`)
- 親 Issue の URL
- サブ Issue の説明 (任意)

$ARGUMENTS

## 手順

### 1. 親 Issue のコンテキストを取得する

```bash
gh issue view <issue-number> --json number,title,body,url
```

詳細なコンテキストとして PLANS_SYNC_MARKER コメントを探す。

### 2. サブ Issue を作成する

以下の点を踏まえて create-issue のガイドラインに従う:
- **必須**: 本文の冒頭に `Part of #{parent-issue-number}` を記載する
- フォーカスされた、実行可能な Issue を作成する

### 3. 親 Issue に紐づける

```bash
ISSUE_URL=$(gh issue create --title "$TITLE" --body "$BODY" --label "sub-issue")
ISSUE_NUMBER=$(echo $ISSUE_URL | grep -o '[0-9]*$')
# IMPORTANT: Use .id (integer), NOT .node_id (string)
SUB_ISSUE_ID=$(gh api /repos/{owner}/{repo}/issues/$ISSUE_NUMBER --jq .id)
gh api --method POST /repos/{owner}/{repo}/issues/{parent-number}/sub_issues \
  -F "sub_issue_id=$SUB_ISSUE_ID"
```

### 4. 複数のサブ Issue の順序を指定する (複数作成する場合)

```bash
gh api --method PATCH /repos/{owner}/{repo}/issues/{parent-number}/sub_issues/priority \
  --input - <<< '{"sub_issue_id": '$SUB_ISSUE_ID', "after_id": '$PREV_SUB_ISSUE_ID'}'
```

## 本文フォーマット

```markdown
Part of #{parent-issue-number}

[Template content or standard structure]
```

## ベストプラクティス

- 親 Issue の本文と PLANS_SYNC_MARKER コメントを文脈として活用する
- サブ Issue はフォーカスされた、単独で完結できる内容にする
- ラベルを統一して付与する
