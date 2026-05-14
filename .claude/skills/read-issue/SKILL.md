---
name: read-issue
description: Fetch a GitHub issue with its sub-issues, walk up to the parent Epic, list sibling issues under that Epic, fetch the body of each sibling issue, attach the implementing PR for each closed sibling with body and diff summary, gather related code, and present as a Japanese summary so the reader can grasp the whole task context including the actual contents of siblings and their PRs
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
   - 本文中 `#NNN` 参照の振り分け（3 分岐、上から順に判定）:
     1. **サブ Issue として既に取得済み**（API or タスクリスト記法 hit） → サブ Issue 一覧へ
     2. **親 Epic として手順 4 で取得予定 / 取得済み** → 関連リンクには **再掲しない**（親 Epic セクションで触れる）
     3. **上記以外**（`Part of #N` 以外の前置詞付き参照 / `[text](#N)` / クロスリポ / Discussion 等） → 「関連リンク」へ分離
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
   - 上記クエリは `number / title / state / url / body / repository.nameWithOwner` を取得する。提示フォーマットで使うフィールドを増やすときはクエリも同時に更新すること
   - `parent` が `null`: 「親 Epic なし」と 1 行記録し手順 5 / 6 をスキップ
   - `parent.repository.nameWithOwner` が `<owner>/<repo>` と異なる（クロスリポ親）: 「親 Epic: クロスリポ参照 — <owner>/<repo>#N」と 1 行記録し「関連リンク」へ回して手順 5 / 6 をスキップ
   - `parent.state` などが取得できないなど例外時: 「親参照あり — 取得不可: <理由>」と 1 行記録し手順 5 / 6 をスキップ

5. **親 Epic 配下の兄弟 Issue 一覧と本文**: まず一覧を取得:
   ```bash
   gh api repos/<owner>/<repo>/issues/<parent_num>/sub_issues --jq '.[] | {number, title, state, url}'
   ```
   - 0 件は「Epic 配下の sub_issues は空」と 1 行明示（タスクリストへフォールバックしない — 公式 API のみを信頼）。0 件なら手順 6 もスキップ
   - 提示時、対象 Issue 行を太字 / マーカーで強調

   続いて **対象 Issue 以外の全兄弟** について本文を取得（手順 7 と並列、兄弟同士も並列）:
   ```bash
   gh issue view <sibling_n> --repo <owner>/<repo> --json number,title,body,state,url
   ```
   - 取得した body から要点 2-4 行を抽出して提示フォーマットの「兄弟 Issue 本文要点」に使う
   - body が空のときは「本文なし」と 1 行
   - 404 / 取得失敗は当該 Issue の要点を「取得失敗: <要約>」とし、skill は止めない

6. **closed 兄弟の実装 PR を取得**（`state == "closed"` の兄弟のみ。`open` には呼ばない）:
   ```bash
   gh issue view <n> --json number,closedByPullRequestsReferences \
     --jq '{number, prs: [.closedByPullRequestsReferences[] | {number, url, state, title}]}'
   ```
   - 空配列の closed Issue は「実装 PR リンクなし」扱い。フィールド非対応など失敗時は 1 行警告で PR 欄 `-`、skill は止めない
   - **closing PR が 1 件でもあれば**、その全 PR について本文と差分サマリを取得（PR ごとに並列、`state == null` 補完もこの 1 呼び出しに含める）:
     ```bash
     gh pr view <pr> --repo <owner>/<repo> --json number,state,title,body,additions,deletions,changedFiles,files
     ```
     - body から要点 2-4 行
     - `additions / deletions / changedFiles` で規模を 1 行（例: `+120 -45 / 8 files`）
     - `files[].path` の上位 5 件を「主な変更ファイル」として 1 行
     - 失敗時は要点を「取得失敗」とし、表の `実装 PR` 欄だけ残す

7. **関連ファイルをコードベースから検索**: 対象 Issue のタイトル・本文から **2-3 個のキーワード**を抽出。**1 シンボル = 1 キーワード**（`audit-log` / `auditLog` / `audit_log` の表記ゆれは同一キーワードの 1 セット）。総数は最大 3 個:
   ```bash
   grep -rln "<keyword>" . \
     | grep -Ev '(^|/)(node_modules|\.next|dist|__generated__|\.claude/worktrees|\.playwright-mcp|\.turbo|coverage|\.git)(/|$)' \
     | head -n 10
   ```
   `--exclude-dir` は BSD/GNU で挙動が割れるため後段 `grep -Ev` を使う。0 件なら「該当なし」

## 並列実行

逐次: 手順 2 → 4（対象 Issue がないと親参照を抽出できない）。並列可: 手順 3 の `missing_nums` 追加取得、手順 5 の兄弟一覧取得 → 兄弟本文取得（一覧が取れた直後に全兄弟を並列）、手順 6 の closed 兄弟ごとの closing PR 抽出と PR 本文取得（PR ごとに並列）、手順 7 — 兄弟が N 件あれば 1 メッセージに 2N 件程度の `gh` 呼び出しを並べる前提

## 提示フォーマット（日本語）

**共通ルール**:
- 行内の Issue / PR 番号や対象行の強調は `**太字**` で統一（絵文字・矢印・色マーカー等は使わない）
- 0 件時の文言は各セクションの規定に従う
- 本文要点の「N 行」「N-M 行」表記は **上限**。body が短く下限に届かない場合は得られた情報のみを使い、内容を水増ししてはならない（パディング禁止）
- 表セルの「実装 PR」列は **表示は `-` で統一**（open 兄弟 / closed だが closing PR なし / 取得失敗、すべて `-`）。手順 6 の内部記録上の区別は表セルには反映しない

1. **対象 Issue サマリ**: `#<番号> <title>` (state) / URL / 本文要点 3-5 行。comments が 0 件のときは comments 行を出さない（「コメント: なし」等の補足行は不要）
2. **サブ Issue 一覧**: 表 `# / title / state`。0 件時は「サブ Issue なし」
3. **親 Epic と全体像**（取れた場合のみ。取れなければ「親 Epic: 取得不可 / なし — <理由>」の 1 行で 4 / 5 セクションへ）。内部要素は次の順で必ず出す:
   - **3-1. 親 Epic サマリ**: `#<num> <title>` (state) / URL / 本文要点 2-4 行
   - **3-2. Epic 配下の Issue 一覧**: 表 `# / title / state / 実装 PR`。対象 Issue 行は `**#<num>**` のように太字で強調、実装 PR 列は `#<pr>（state）`、open 兄弟と PR なし closed は `-`
   - **3-3. 進捗サマリ**: `closed: M / N、open: K / N` の 1 行
   - **3-4. 兄弟 Issue 本文要点**: 対象 Issue 以外の兄弟ごとに `#<num>: 要点 2-4 行`。兄弟が 0 件（自分のみ）のときは「兄弟 Issue 本文要点: なし（兄弟は対象のみ）」の 1 行
   - **3-5. 実装 PR サマリ**: closing PR を持つ closed 兄弟ごとに、`#<pr> <title>` / 本文要点 2-4 行 / `+A -D / F files` / 主な変更ファイル上位 5 件。closing PR を持つ closed 兄弟が 0 件のときは「実装 PR サマリ: なし」の 1 行
4. **関連リンク**: 手順 3 の 3 分岐ルールで「関連リンク」へ振り分けたもの（クロスリポ参照 / Discussion / ADR / Design Doc 等）。0 件時は「関連リンク: なし」
5. **関連コード**: 相対パス。0 件時は「関連コード: なし」

## 設計上の制約

- 探索範囲は **親 Epic 1 階層上 + 兄弟（本文込み） + 完了兄弟の実装 PR（本文・差分サマリ込み）** に限定。祖父母 Epic は辿らない（呼び出し数が指数的に増えるため。深掘りが必要なら親 Epic 番号で再実行する）
- **推測補完は禁止**。GraphQL `Issue.parent` が `null` のときに本文中の `#NNN` や `Part of` 等のテキストから類推して親を取得しない（UI で紐づいていない＝親なしと扱う）
- `sub_issues` API が返す state は `open` / `closed` の 2 値。原文のまま提示
- 兄弟本文・PR 本文取得は **タイトル止まりにしない約束** を skill の責務として明示する（description で grasp the whole task context "including the actual contents" と謳っているため、省略する場合は明示的な理由提示が必須）
