---
name: read-issue
description: Read a GitHub issue, its parent and sub-issues, and relevant code. Use --full when the user needs all sibling issue bodies and their implementing PRs.
argument-hint: <issue-number-or-url> [--full]
---

# Read Issue

引数: $ARGUMENTS

## 取得範囲

既定は対象 Issue の理解に必要な範囲。`--full` または Epic 全体の詳細調査を依頼された場合は、全兄弟の本文と完了兄弟の実装 PR まで取得する。

1. 番号・`#番号`・URL から対象を特定する。URL の owner/repo を以後の `gh` 呼び出しに使う。
2. `gh issue view <n> --repo <owner>/<repo> --json number,title,body,state,url,comments` で取得する。404・認証・通信エラーは報告して停止し、番号の類推探索はしない。PR として取得された場合は区別して明示する。
3. `--json subIssues` で子の一覧を取得する。本文のタスクリスト参照で補完し、取得済みの Issue を重複取得しない。通常の関連リンクと子を区別する。
4. `--json parent` で親を1階層だけ辿る。親は公式紐づけを正とし、本文の `Part of` 等から推測しない。親なし・取得失敗は区別する。クロスリポの親は関連リンクとして示し、探索を広げない。
5. 同一リポの親があれば、その本文と子一覧から全体像を確認する。兄弟の本文・実装 PR は、対象の依存関係や既存実装の把握に必要なものだけ追加取得する。
6. 対象から関連するシンボルを選び、`rg` でコードを絞る。生成物・依存ディレクトリを探索対象にしない。

## 全件調査 (`--full`)

手順5を以下に拡張する。独立した取得は並列化し、同じ本文・PRは再利用する。

- 対象以外の全兄弟について `gh issue view <n> --json number,title,body,state,url`。
- closed 兄弟について `--json closedByPullRequestsReferences` で closing PR を取得する。
- 各 PR は `gh pr view <n> --json number,state,title,body,additions,deletions,changedFiles,files` で本文・規模・主な変更ファイルを確認する。差分全文は必要な PR だけ取得する。
- 一部の取得失敗は当該項目に明示し、残りを続ける。本文なし・PRなしを推測で埋めない。祖父母 Epic は辿らない。

## 報告

日本語で対象の要点、親子・依存関係、関連コード、未確認事項を簡潔に示す。Issue・PR はリンクする。
全件調査では兄弟一覧・進捗・各本文と実装 PR の要点も含める。通常モードで省いた詳細を取得済みのように書かない。空の節や行数合わせの説明は不要。
