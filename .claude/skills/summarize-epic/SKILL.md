---
name: summarize-epic
description: Summarize GitHub Epic issue with sub-issues and related PRs. Use when reviewing epic progress or getting implementation overview.
disable-model-invocation: true
---

# Summarize Epic

GitHub の Epic Issue とそのサブ Issue、関連 PR を集約してサマリーを生成する。

## 引数

`<epic-issue-url>`: GitHub Epic Issue の URL (例: https://github.com/owner/repo/issues/123)

$ARGUMENTS

## 手順

### 1. Epic Issue を取得する

- URL からリポジトリ名と Issue 番号を抽出する
- Epic の詳細 (タイトル、本文、状態、コメント) を取得する

### 2. サブ Issue を取得する

```bash
gh api repos/<owner>/<repo>/issues/<epic-number>/sub_issues --paginate --jq '.[].number'
```

- 失敗時: エラーをそのまま報告する
- 成功時: サブ Issue の状態 (完了/進行中) を集計する

### 3. 関連 PR を取得する

- GraphQL API を使って Issue のタイムラインから PR を取得する
- PR 本文で Issue への参照を検索する
- Epic 本文から PR 番号を抽出する
- PR の詳細 (タイトル、状態、mergedAt、追加/削除行数、ファイル数) を取得する

### 4. 出力フォーマット

```markdown
# Epic Summary

## Basic Info
- **Epic**: <url>
- **State**: <state>
- **Assignees**: <assignee-list>

## Overview
<Epic body summary>

## Key Comments
<Important decisions and changes from Epic comments>

## Sub-issue Progress
- **Completed**: <completed>/<total> issues
- **Progress**: <percentage>%

## Implementation Highlights

### Merged Changes
- <pr-url>: <summary of main changes>

### In Progress
- <pr-url>: <change overview>

## Overall Progress
- **Completed**: <completed>/<total> issues
- **Progress**: <percentage>%
- **Remaining**: <pending or in-progress tasks>

## Issues & Gaps
<Discrepancies between Epic spec and implementation, blockers, concerns>

## Next Steps
<Upcoming milestones>
```

## コマンド

```bash
# Epic issue
gh issue view <number> --repo <owner>/<repo> --json title,body,state,comments

# Sub-issues
gh api repos/<owner>/<repo>/issues/<epic-number>/sub_issues --paginate --jq '.[].number'

# Related PRs (GraphQL)
gh api graphql -f query='
  {
    repository(owner: "<owner>", name: "<repo>") {
      issue(number: <issue-number>) {
        timelineItems(first: 100, itemTypes: [CROSS_REFERENCED_EVENT]) {
          nodes {
            ... on CrossReferencedEvent {
              source {
                ... on PullRequest { number title state merged mergedAt }
              }
            }
          }
        }
      }
    }
  }
'

# PR details
gh pr view <pr-number> --repo <owner>/<repo> --json title,body,state,mergedAt,additions,deletions,changedFiles
```
