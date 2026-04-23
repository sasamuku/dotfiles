---
name: update-plan-from-subissues
description: Update PLANS.md content based on linked sub-issues status
disable-model-invocation: true
---

# Update Plan from Sub-issues

連携済みのサブ Issue を分析し、その現在の状態を PLANS.md に反映して更新する。

## 引数

$ARGUMENTS

## プロセス

### 1. PLANS.md のフロントマターを読み取る

`issue:` フィールド (親 Issue 番号) を抽出する。見つからない場合はエラーで終了する。

### 2. 親 Issue からサブ Issue を取得する

```bash
gh api repos/{owner}/{repo}/issues/{issue}/sub_issues \
  --jq '.[] | {number, title, state}'
```

### 3. サブ Issue と PLANS.md の内容を分析する

各サブ Issue について:
```bash
gh issue view {sub-issue-number} --json number,title,body,state
```

更新が必要な箇所を特定する:
- **Validation & Acceptance Criteria**: 完了済み項目にチェックを付ける
- **Open Questions**: 解決済みの問いを削除する
- **Discoveries & Insights**: 議論から得られた発見を追加する
- **Decision Log**: サブ Issue で下された決定を追加する
- **Follow-up Issues**: 新しいサブ Issue で内容を更新する

### 4. PLANS.md を更新する

- Edit ツールで既存の内容を更新する
- 完了済みのサブ Issue のチェックボックスを `- [x]` に変更する
- 既存の構造は変更しない

### 5. GitHub へ同期する (任意)

更新後、`/sync-plan` の実行を提案する。

## ガイドライン

- 新しいセクションを追加しない
- 既存の情報を重複させない
- サブ Issue の進捗を反映する内容のみ更新する
- 既存のナラティブと構造を維持する
