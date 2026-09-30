---
name: create-sub-issue
description: Create a sub-issue linked to a parent GitHub issue, honoring repository-specific issue conventions.
disable-model-invocation: true
---

# Create Sub-issue

引数: $ARGUMENTS (親Issue番号・URL、任意のサブIssue説明)。対象リポジトリを解決し、以降の `gh` 操作で明示する。

## 調査・ドラフト

1. 親Issueの本文・ラベル・Projectsを `gh issue view --json number,title,body,url,labels,projectItems` で取得する。計画など補足コメント (`PLANS_SYNC_MARKER` 等) があれば読む。
2. 親・既存サブIssueのタイトルを2〜3件と `.github/ISSUE_TEMPLATE/` を確認する。規約がなければ接頭辞・補足のカッコ書きを省いたタイトルと、親の本文構造を使う。補足情報は本文へ移す。
3. ラベルは `gh label list --repo <owner>/<repo> --limit 100` で存在を確認したものだけ使う。不明なら省略して確認する。
4. 親のProject・Issue Type・Teamを確認し、原則同じ値を設定する。必要な照会・更新例だけ [projects.md](references/projects.md) を読む。**Status・Priorityは明示要求がなければ変更しない。**
5. 単独で実行できる粒度のドラフトを提示し、ユーザー承認を得て作成へ進む。本文冒頭は `Part of #<親番号>`。リンクはrepoルート相対またはフルGitHub URLとし、作業ディレクトリ相対は使わない。テンプレートのHTMLコメントは記入内容に置き換えるか削除する。

## 作成・紐付け

承認済み本文をファイルに保存して作成する。必要なラベルだけ `--label` で指定する。

```bash
gh issue create --repo <owner>/<repo> --title "$TITLE" --body-file "$BODY_FILE"
```

返されたURLからIssue番号を取得し、親へ紐付ける。**RESTの整数 `.id` を使い、GraphQLの `.node_id` と混同しない。**

```bash
SUB_ISSUE_ID=$(gh api repos/<owner>/<repo>/issues/<issue-number> --jq .id)
gh api --method POST repos/<owner>/<repo>/issues/<parent-number>/sub_issues \
  -F "sub_issue_id=$SUB_ISSUE_ID"
```

必要なProject・Issue Type・Teamを設定する。複数起票では各Issueの作成・紐付け・フィールド設定を順に行う。途中失敗は作成済みURLと未完了処理を報告し、Issueを重複作成しない。

末尾への追加はPOSTだけでよい。複数Issueの表示順を変える必要がある場合だけ、整数IDで順序を指定する。

```bash
gh api --method PATCH repos/<owner>/<repo>/issues/<parent-number>/sub_issues/priority \
  -F "sub_issue_id=$SUB_ISSUE_ID" -F "after_id=$PREV_SUB_ISSUE_ID"
```
