---
description: GitHub Epic issueの実装内容を概略表示・要約
allowed-tools: Bash, TodoWrite
---

## Task

指定したGitHub Epic issueとその配下のsub-issue、関連PRの実装内容を集約して要約します。

### Arguments

- `<epic-issue-url>`: GitHub Epic issue URL (例: https://github.com/owner/repo/issues/123)

### 処理手順

1. **Epic issue情報の取得**
   - URLからrepository名とissue番号を抽出
   - Epic issueの詳細（title, body, state, comments）を取得

2. **Sub-issueの取得**
   - GitHub Sub-issues API (`gh api repos/<owner>/<repo>/issues/<epic-number>/sub_issues`) を使用
   - 失敗時は他の手段を試さず、エラーとして報告
   - 成功時: 各sub-issueの状態を集計（完了/進行中）

3. **関連PRの取得**
   - GraphQL APIでissueのタイムラインからPR取得
   - PR本文でissue番号を検索
   - Epic本文からPR番号を直接抽出
   - 各PRの詳細（title, state, mergedAt, additions, deletions, files）を取得

4. **出力format**

```markdown
# Epic issue概要

## 📋 基本情報
- **Epic**: <url>
- **状態**: <state>
- **Assignees**: <assignee-list>

## 📝 Epic概要
<Epic本文の要約>

## 💬 重要なコメント
<Epic Issueのコメントから重要な決定事項や変更点>

## 🔗 Sub-issue進捗
- **完了**: <completed>/<total> issues
- **進捗率**: <percentage>%

## 🚀 実装Highlight

### マージ済み変更
- <pr-url>: <主要な変更点の要約>

### 進行中の作業
- <pr-url>: <変更内容の概要>

## 📊 全体進捗
- **完了**: <completed>/<total> issue
- **進捗率**: <percentage>%
- **残作業**: <未着手または進行中のタスクリスト>

## ⚠️ 課題・乖離点
<Epic記載内容と実装の相違点、Blockerや懸念事項>

## 📅 今後の予定
<次のステップやマイルストーン>
```

### エラーハンドリング

- 権限エラー: Private repositoryへのアクセス権限を確認
- Issue番号の解析エラー: URL形式の妥当性を検証
- API制限: Rate limitに達した場合は待機または分割実行を提案
- Sub-issue取得失敗: エラーメッセージをそのまま表示

### 実装コマンド例

```bash
# Epic issue取得
gh issue view <number> --repo <owner>/<repo> --json title,body,state,comments

# Sub-issue取得
gh api repos/<owner>/<repo>/issues/<epic-number>/sub_issues --paginate --jq '.[].number'

# PR検索（GraphQL）
gh api graphql -f query='
  {
    repository(owner: "<owner>", name: "<repo>") {
      issue(number: <issue-number>) {
        timelineItems(first: 100, itemTypes: [CROSS_REFERENCED_EVENT]) {
          nodes {
            ... on CrossReferencedEvent {
              source {
                ... on PullRequest {
                  number
                  title
                  state
                  merged
                  mergedAt
                }
              }
            }
          }
        }
      }
    }
  }
'

# PR詳細取得
gh pr view <pr-number> --repo <owner>/<repo> --json title,body,state,mergedAt,additions,deletions,changedFiles
```
