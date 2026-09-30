---
name: babysit
description: Triage PR comments and CI failures. Default reports recommendations; --auto fixes, commits, pushes, replies, and monitors until completion. --once disables recurring execution.
allowed-tools: Bash(git *), Bash(gh *), Read, Edit, Write
---

# Babysit

引数: $ARGUMENTS (PR番号・URL、省略時は現在のブランチ。`--auto` / `--once`)

- 既定は読み取りと修正案の提示まで。編集・commit・push・返信はユーザーの指示後。
- `--auto` はこのPRの低リスクな修正・commit・push・返信を自律実行する。プロダクト判断や範囲外の変更は保留する。

## ループ

直接の `--auto` 呼び出しでは `/loop 5m /babysit --auto <PR>` を開始する。`--once` や loop からの再実行では新しいループを作らない。loop 機構が使えなければ単発実行として明示する。
PR終了、または対応事項なし・全必須チェック完了・mergeable確認済みで停止する。pending 中は継続し、権限・インフラ等で進めない場合は未解決理由を報告して停止する。

## Step 1: 対象確認

`gh pr view` で番号・URL・状態・headブランチとSHAを取得する。APIの owner/repo はPRのURLから解決する。merged/closed ならループも停止する。PRが見つからなければその旨を報告する。
修正・push 前に対象PRの worktree にいることを確認する。

## Step 2: コメント

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments --paginate \
  --jq '[.[] | {id,in_reply_to_id,path,line,body,user:{login:.user.login,type:.user.type}}]'
```

`in_reply_to_id` でスレッドを再構成する。修正済み宣言は対象headのコードと照合し、単に返信があるだけでは対応済みにしない。同じ根本原因の重複指摘はまとめる。表示名は人間なら login、bot なら識別できる短い名称にする。

## Step 3: CI

コメントの有無にかかわらず `gh pr checks <N> --json name,state,link` を確認する。失敗は対応する run の `gh run view <run-id> --log-failed` を読む。URL内の job ID と run ID を混同せず、対象ブランチ・head SHA の run か確認する。pending は成功と区別する。

## Step 4: 分類

| 対象 | 優先度 |
|---|---|
| バグ・セキュリティ・破壊的変更、PR起因のCI失敗 | Must |
| 設計判断・未確認事項・flakyの疑い | Investigate |
| スタイル・軽微な提案 | Info |
| PRの変更で直せないインフラ・権限等 | Skip |

コメントの明示指定 (`[must]` / `[imo,ask,fyi]` / `[nits]`、または同等のラベル・絵文字) を分類に使い、実コードで妥当性を確認する。
優先度とは別に、実害・修正コスト・PR範囲・既存問題かを評価し、対応 Yes / No / 保留と根拠を付ける。

flaky と判断して再実行するには、失敗がタイムアウト・通信系のみで、コード由来のアサーション失敗・例外がなく、baseの直近runと直近10run中2回以上で同一テストが成功していることを確認する。

## Step 5: 対話モード

`ID / 優先度 / 対応推奨 / Reviewer / 場所 / 問題と修正案` を表で提示する。修正推奨・保留は該当コードを読み、影響範囲を示す。CI失敗も含め、対応対象の指示を待つ。
返信のみ依頼された場合は、ユーザーが対応済みと確認した対象に Step 8 を適用する。

## Step 6: 自律修正

- Yes の Must、妥当で低リスクな Investigate、些細で安全な Info を直す。No・保留・Skip は直さず理由を記録する。
- CIはリポジトリの実在する検証コマンドで原因を確認する。テストの意図が誤っていない限り、テストを弱めて通さない。
- flaky の条件を満たす場合だけ同じ run を1回再実行する。
- 同じ問題の修正・検証が3巡しても進展しなければ、残課題を報告して自律修正とループを止める。

## Step 7: Commit・push

修正があれば `/commit -y` と `git push`。upstream未設定なら対象PRの送信先を確認して設定する。無関係な変更を含めない。コミットを引用した返信は、リモートへの反映を確認してから投稿する。

## Step 8: 返信

処理したルートコメントにスレッド返信する。すでに同じ判断を返信済みなら重複投稿しない。

```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments -X POST \
  -f body="<reply>" -F in_reply_to=<comment-id>
```

修正はコミットをリンクし、対応しない・保留の場合は具体的な理由を短く書く。未実施の対応を完了と書かない。

## Step 8.5: Devin Review

Devin (`devin-ai-integration[bot]`) のコメントまたはレビューがあるPRだけ対象。head SHA の commit status から `context == "Devin Review"` の最新状態を確認する。

```bash
gh api repos/{owner}/{repo}/commits/{head-sha}/status \
  --jq '.statuses[] | select(.context == "Devin Review") | {state,updated_at}'
```

- pending: 再キックせず待つ。30分を超えれば失敗として報告し、成功・指摘なしと扱わない。
- success: 同じSHAを再キックしない。新しい指摘の有無を確認する。
- 状態なし: Issueコメントを `--paginate` で取得し、直近の `/devin review` が5分以内なら待つ。それ以外は `gh pr comment <N> --body "/devin review"` でキックする。
- failure/error: 失敗を報告し、未完了として扱う。

## Step 9: 報告・停止

修正・skip・返信・CI・Devinの状態とPR/コミットへのリンクを短く報告する。終了時は自分が開始したループも止める。
pending、未解決の必須チェック、レビュー待ち・コンフリクトがあれば mergeable と断定しない。
