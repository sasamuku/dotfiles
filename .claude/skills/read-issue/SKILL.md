---
name: read-issue
description: Fetch a GitHub issue with its sub-issues (GitHub sub-issue API + body task list) and related code, then present as a Japanese 3-section summary
disable-model-invocation: true
---

# Read Issue

GitHub の Issue を取得し、サブ Issue と併せて表示する。

## 引数

Issue 番号 (例: `123` または `#123`)

$ARGUMENTS

## 手順

1. 引数から Issue 番号を抽出する
   - `123` / `#123` / `https://github.com/<owner>/<repo>/issues/<n>` のいずれも受け付ける
   - URL 形式の場合は `<owner>/<repo>` も記録し、以降の `gh` 呼び出しに `--repo <owner>/<repo>` を付与する
2. Issue の詳細を取得する:
   ```bash
   gh issue view <issue-number> --json number,title,body,state,url,comments
   ```
   - **取得失敗時の分岐**:
     - **404 / 存在しない番号**: 親 Issue サマリに「取得不可: #<番号> は存在しません」と 1 行明示し、サブ Issue 一覧と関連コードは **省略せずに「取得不可のため対象なし」と明記**して中断する。隣接番号の探索や類推による補完は **行わない**（誤情報の出力を防ぐ）
     - **取得結果が PR**: `gh issue view` は PR でも成功する（Issue/PR は番号空間共通）。PR が返ったら親 Issue サマリの先頭に `[PR として取得]` のヘッダを 1 行付け、本文要点はそのまま提示する。サブ Issue は通常通り取得を試みる
     - **認証エラー / ネットワーク失敗**: 親 Issue サマリに「取得失敗: <エラー要約>」を 1 行明示して中断
3. **サブ Issue は次の優先順で抽出する**:
   1. **一次ソース**: GitHub 公式 sub-issue API
      ```bash
      gh api repos/<owner>/<repo>/issues/<n>/sub_issues --jq '.[] | {number, title, state, url}'
      ```
   2. **補完**: 本文タスクリスト記法 `- [ ] #NNN` / `- [x] #NNN` （1 と dedup）
   3. **サブ扱いにしない**: 上記に該当しない本文中の `#NNN` / `[text](#NNN)` / 「関連 Epic」「関連 Issue」「関連 Discussion」等の文脈注記はすべて **「関連リンク」として別セクションに分離** する（サブ issue として列挙しない）
4. サブ Issue の詳細を揃える（**dedup と追加取得は次の擬似コード通りに行う**。API レスポンスは正としてそのまま使い、再取得しない）:

   ```
   api_subs       = 手順 3.1 のレスポンス（number/title/state/url が揃っている）
   tasklist_nums  = 手順 3.2 で本文から抽出した番号集合
   api_nums       = { s.number for s in api_subs }

   # API にあれば API のデータを正とする → 追加 gh issue view は呼ばない
   # タスクリスト固有の番号だけを補完取得対象とする
   missing_nums   = tasklist_nums - api_nums
   for n in missing_nums:
     gh issue view <n> --json number,title,body,state,url   # ここでだけ呼ぶ

   final_subs = api_subs ∪ { 上記 for ループで取得したもの }
   ```

   - 追加 `gh issue view` の呼び出し回数は **必ず `len(missing_nums)` 件**。これを超えたら手順違反
   - api_subs に既に揃っている Issue を再取得しない。`title` が欠けて見えても再取得しない（`--jq` のフィルタを正としない、生レスポンスを使う）
   - Discussion（`gh issue view` で取得不可）は「関連リンク」側に回す
5. 関連ファイルをコードベースから検索する:
   - 親 Issue のタイトル・本文から 2-3 個のキーワード（機能名 / 固有識別子 / ファイル名候補）を抽出
   - 環境非依存な形で `grep -rln`（リポジトリルート）を実行し、結果を pipe でフィルタする:
     ```bash
     grep -rln "<keyword>" . \
       | grep -Ev '(^|/)(node_modules|\.next|dist|__generated__|\.claude/worktrees|\.playwright-mcp|\.turbo|coverage)(/|$)' \
       | head -n 10
     ```
     （`--exclude-dir` は BSD/GNU / 相対パス階層で挙動が割れるため、`grep -Ev` で後段フィルタする方が確実）
   - 0 件なら「該当なし」と明示
6. Issue 情報を日本語 3 セクション構成で提示する:
   1. **親 Issue サマリ**: `#<番号> <title>` (state) / URL / 本文要点 3-5 行
   2. **サブ Issue 一覧**: 表形式で `# / title / state`。0 件の場合は「サブ Issue なし」と明示し、**続けて「関連リンク」セクションを出す**
   3. **関連コード**: 相対パスの箇条書き。0 件なら「該当なし」
