---
name: read-issue
description: Fetch a GitHub issue with its sub-issues, walk up to the parent Epic, list sibling issues under that Epic, attach the implementing PR for each closed sibling, gather related code, and present as a Japanese summary so the reader can grasp the whole task context
disable-model-invocation: true
---

# Read Issue

GitHub の Issue を取得し、サブ Issue・親 Epic・Epic 配下の兄弟 Issue・完了済み Issue の実装 PR まで含めてタスクの全体像を提示する。

## 引数

Issue 番号 (例: `123` または `#123`)

$ARGUMENTS

## 手順

1. **引数から Issue 番号を抽出**: `123` / `#123` / `https://github.com/<owner>/<repo>/issues/<n>` を受け付ける。URL 形式なら `<owner>/<repo>` を記録し、以降の `gh` 呼び出しに `--repo <owner>/<repo>` を付与

2. **対象 Issue を取得**: `gh issue view <n> --json number,title,body,state,url,comments`
   - 404: 「取得不可: #<番号> は存在しません」と 1 行明示し以降「取得不可のため対象なし」で中断。隣接番号探索・類推補完は禁止
   - PR が返った場合: サマリ先頭に `[PR として取得]` を 1 行付け、サブ Issue・親 Epic 探索は通常通り続行
   - 認証エラー / ネットワーク失敗: 「取得失敗: <要約>」と 1 行明示して中断

3. **サブ Issue を抽出 → 詳細を揃える**
   - 一次ソース: `gh api repos/<owner>/<repo>/issues/<n>/sub_issues --jq '.[] | {number, title, state, url}'`
   - 補完: 本文タスクリスト記法 `- [ ] #NNN` / `- [x] #NNN` を抽出（API と dedup）
   - サブ扱いにしない: 上記以外の本文中 `#NNN` / `[text](#NNN)` / 「関連 Epic」「関連 Issue」「関連 Discussion」等は「関連リンク」へ分離
   - dedup 規則（API レスポンスを正とする。再取得しない）:
     ```
     missing_nums = tasklist_nums - { s.number for s in api_subs }
     for n in missing_nums:
       gh issue view <n> --json number,title,body,state,url   # ここでだけ呼ぶ
     ```
   - 追加 `gh issue view` の呼び出しは **必ず `len(missing_nums)` 件**。`--jq` フィルタは正としない（生レスポンスを使う）。Discussion は「関連リンク」へ

4. **親 Epic を上向きに 1 階層辿る**（全体像把握の中核）
   - 一次ソースは GitHub の Issue 紐づけ機能（GraphQL `Issue.parent`）。本文の `Part of #N` / `Parent: #N` / `Epic: #N` 等のテキスト規約は使わない（UI 上の公式紐づけが正）
   - 取得:
     ```bash
     gh api graphql -f query='
       query($owner:String!, $repo:String!, $num:Int!) {
         repository(owner:$owner, name:$repo) {
           issue(number:$num) {
             parent { number title state url body
               repository { nameWithOwner }
             }
           }
         }
       }' -F owner=<owner> -F repo=<repo> -F num=<n>
     ```
   - `parent` が `null`: 「親 Epic なし」と 1 行記録し手順 5 / 6 をスキップ
   - `parent.repository.nameWithOwner` が `<owner>/<repo>` と異なる（クロスリポ親）: 「親 Epic: クロスリポ参照 — <owner>/<repo>#N」と 1 行記録し「関連リンク」へ回して手順 5 / 6 をスキップ
   - `parent.state` などが取得できないなど例外時: 「親参照あり — 取得不可: <理由>」と 1 行記録し手順 5 / 6 をスキップ

5. **親 Epic 配下の兄弟 Issue 一覧**: `gh api repos/<owner>/<repo>/issues/<parent_num>/sub_issues --jq '.[] | {number, title, state, url}'`
   - 0 件は「Epic 配下の sub_issues は空」と 1 行明示（タスクリストへフォールバックしない — 公式 API のみを信頼）
   - 提示時、対象 Issue 行を太字 / マーカーで強調

6. **closed 兄弟の実装 PR を取得**（`state == "closed"` の兄弟のみ。`open` には呼ばない）:
   ```bash
   gh issue view <n> --json number,closedByPullRequestsReferences \
     --jq '{number, prs: [.closedByPullRequestsReferences[] | {number, url, state, title}]}'
   ```
   - 空配列の closed Issue は「実装 PR リンクなし」扱い。フィールド非対応など失敗時は 1 行警告で PR 欄 `-`、skill は止めない
   - **PR state が `null` のときのみ** `gh pr view <pr> --repo <owner>/<repo> --json state` で 1 件補完（値があれば追加取得しない）

7. **関連ファイルをコードベースから検索**: 対象 Issue のタイトル・本文から **2-3 個のキーワード**を抽出。**1 シンボル = 1 キーワード**（`audit-log` / `auditLog` / `audit_log` の表記ゆれは同一キーワードの 1 セット）。総数は最大 3 個:
   ```bash
   grep -rln "<keyword>" . \
     | grep -Ev '(^|/)(node_modules|\.next|dist|__generated__|\.claude/worktrees|\.playwright-mcp|\.turbo|coverage|\.git)(/|$)' \
     | head -n 10
   ```
   `--exclude-dir` は BSD/GNU で挙動が割れるため後段 `grep -Ev` を使う。0 件なら「該当なし」

## 並列実行

逐次: 手順 2 → 4（対象 Issue がないと親参照を抽出できない）。並列可: 手順 3 の `missing_nums` 追加取得、手順 5、手順 6 の closed 兄弟ごとの呼び出し、手順 7 — 可能な限り 1 メッセージで並列にまとめる

## 提示フォーマット（日本語）

1. **対象 Issue サマリ**: `#<番号> <title>` (state) / URL / 本文要点 3-5 行
2. **サブ Issue 一覧**: 表 `# / title / state`。0 件は「サブ Issue なし」
3. **親 Epic と全体像**（取れた場合のみ。取れなければ「親 Epic: 取得不可 / なし — <理由>」の 1 行）
   - 親 Epic サマリ: `#<num> <title>` (state) / URL / 本文要点 2-4 行
   - Epic 配下の Issue 一覧: 表 `# / title / state / 実装 PR`（対象行を強調、実装 PR は `#<pr>（state）`、open 兄弟と PR なし closed は `-`）
   - 進捗サマリ: `closed: M / N、open: K / N`
4. **関連リンク**: 本文中の `#NNN` / クロスリポ参照 / Discussion / ADR / Design Doc 等
5. **関連コード**: 相対パス。0 件なら「該当なし」

## 設計上の制約

- 探索範囲は **親 Epic 1 階層上 + 兄弟 + 完了兄弟の実装 PR** に限定。祖父母 Epic は辿らない（呼び出し数が指数的に増えるため。深掘りが必要なら親 Epic 番号で再実行する）
- **推測補完は禁止**。GraphQL `Issue.parent` が `null` のときに本文中の `#NNN` や `Part of` 等のテキストから類推して親を取得しない（UI で紐づいていない＝親なしと扱う）
- `sub_issues` API が返す state は `open` / `closed` の 2 値。原文のまま提示
