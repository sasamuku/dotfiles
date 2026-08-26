---
name: babysit
description: Triage PR review comments and CI failures. Default mode categorizes and presents findings for user decision; --auto mode autonomously fixes, commits, pushes, replies, re-kicks Devin Review (/devin review) after pushing fixes when Devin is reviewing the PR, and self-starts a 5-minute recurring loop (/loop 5m /babysit --auto) until the PR is mergeable or merged.
allowed-tools: Bash(git *), Bash(gh *), Read, Edit, Write
---

# PR の管理 (Babysit)

PR のレビューコメントと CI ステータスをトリアージするワークフロー。2 つのモードを持つ。

- **対話モード (デフォルト)**: 分類テーブルを提示してユーザーの判断を待つ。**ファイルの編集・commit・push・返信は行わない** (返信はユーザーの指示後のみ)。
- **自律モード (`--auto`)**: ユーザー操作なしで判断し、修正 → commit → push → 返信まで完走する。`/loop 5m /babysit --auto` での無人運転を想定。

## 引数

$ARGUMENTS

- PR 番号または URL (省略時は現在のブランチの PR)
- `--auto` — 自律モード
- `--once` — 自律モードを単発実行する (ループを起動しない)

## 自律モードのループ自動起動

ユーザーが `/babysit --auto` を**直接**打った場合、単発実行では終わらせず定期実行を開始する:

1. `/loop` スキルを `5m /babysit --auto` を対象に起動する (= `/loop 5m /babysit --auto` 相当)
2. 以降の各実行は loop からの再実行として Step 1 から走る

**二重起動ガード**: この呼び出しが `/loop` からの再実行 (wakeup) である場合は、ループを再起動せずそのまま Step 1 から単発実行する。`--once` 指定時も同様。

**ループ停止条件**: 次のいずれかの停止シグナルを出したら、ループ実行中であればループも終了する (dynamic loop なら `ScheduleWakeup {stop: true}`):

- `✅ PR is merged/closed. Stopping.` (Step 1)
- `✅ No actionable comments or CI failures — PR is mergeable.` (Step 9)

Devin Review が pending の間 (Step 8.5) はこの停止シグナルを出さない — レビュー完了を次回実行で拾うまでループを継続する。

---

## 共通: Step 1 — PR を特定する

```bash
gh pr view [pr_number] --json number,headRepository,state -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name, state: .state}'
```

- PR が見つからない場合: 対話モードではその旨を報告、自律モードでは静かに終了する。
- state が `MERGED` または `CLOSED` なら `✅ PR is merged/closed. Stopping.` と出力して終了する。

## 共通: Step 2 — 全レビューコメントを取得する

`--paginate` を必ず付ける (付けないとデフォルト 30 件で打ち切られ、大きな PR で取りこぼす)。

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

返信スレッドを再構成する:

- `in_reply_to_id` が**ある**コメントは「返信」として親コメントの下にぶら下げる。独立エントリとして扱わない。
- 返信に `✅ Resolved` / `✅ Addressed` / "Fixed in xxx" 等の解決宣言が含まれていれば、親コメントを **`✅ Resolved` 扱い**にする (優先度は格下げしない)。
- AI bot が自分の元コメントに後から `✅ Addressed in commits xxx..yyy` と追記するケース (`in_reply_to` なし) も同様に `✅ Resolved` 扱い。

**未対応コメント** = ルートコメントのうち、返信がなく `✅ Resolved` でもないもの。以降の処理対象はこれ。

## 共通: Step 3 — CI の失敗を取得する

**Step 2 の結果 (コメント有無) に関わらず常に実行する。**

```bash
gh pr checks {pr_number} --json name,state,link -q '.[] | select(.state == "FAILURE")'
```

- 結果が空ならスキップ (すべて pass / pending)。
- 失敗があれば、各 `link` の末尾の数値 (run_id) を抽出してジョブログを取得する:

  ```bash
  run_id=$(echo "{link}" | grep -oE '[0-9]+$')
  gh run view "$run_id" --log-failed
  ```

  `link` が無い場合のフォールバック:

  ```bash
  gh run list --branch "$(git branch --show-current)" --json databaseId,conclusion \
    -q '.[] | select(.conclusion == "failure") | .databaseId' | head -1
  ```

## 共通: Step 4 — 分類する

### レビュアーの正規化

`user.login` と `user.type` から判定する。

- `user.type == "User"` → `Human: <login>` (例: `Human: alice`)
- `user.type == "Bot"` → 下記マッピング表で表示名に正規化:

| login パターン | 表示名 |
|---|---|
| `coderabbitai[bot]` | CodeRabbit |
| `devin-ai-integration[bot]` | Devin |
| `copilot-pull-request-reviewer[bot]` / `github-copilot[bot]` | Copilot |
| `claude[bot]` | Claude |
| 上記以外の `*[bot]` | `[bot]` サフィックスを除去し、ハイフン/アンダースコアを空白に変換してタイトルケース化 (例: `foo-bar[bot]` → `Foo Bar`) |

### コメントの優先度

複数該当する場合は左の列が優先 (明示プレフィックス > 絵文字 > 内容判断)。

| シグナル | 値の例 | 優先度 |
|---|---|---|
| 本文先頭の角括弧プレフィックス | `[must]` | 🔴 Must |
| 〃 | `[imo]` / `[ask]` / `[fyi]` | 🟡 Investigate |
| 〃 | `[nits]` | 🟢 Info |
| 本文先頭の絵文字 + キーワード | `🔴` / `Critical:` / `Must:` | 🔴 Must |
| 〃 | `🟡` / `Warning:` / `Investigate:` | 🟡 Investigate |
| 〃 | `🟢` / `Suggestion:` / `Info:` | 🟢 Info |
| プレフィックス無し (内容で判断) | バグ・セキュリティ問題・破壊的変更 | 🔴 Must |
| 〃 | 設計の検討余地・要判断項目 | 🟡 Investigate |
| 〃 | スタイル・軽微な提案・情報提供 | 🟢 Info |

### CI 失敗の分類

ログから原因を特定して分類する:

- 🔴 **Must** — lint / format / type check / テスト失敗で、原因がこの PR の変更に明確に帰属するもの
- 🟡 **Investigate** — flaky テストの疑い、外部依存 / ネットワーク起因の可能性があるもの
- ⚫ **Skip** — インフラ障害、シークレット不足など PR の変更では直せないもの

flaky の判定は次を**全て**満たしたときに「明確」とみなす:

- ログにプロダクションコード由来のアサーション失敗 / 例外が**ない** (タイムアウト・ネットワーク系のみ)
- 同一テストが main / base ブランチの直近 run で成功している
- 直近 10 run の履歴で 2 回以上成功している

### Value 判定 — この PR で対応すべきか

Priority は**深刻度**、Value は**この PR で対応すべきか**を示す独立軸。Must でも Value=No (既存問題・別 PR スコープ) や、Info でも Value=Yes (1 行修正) はあり得る。

**両モードとも全対象に必ず実施する**。自律モードでは Step 6 の act/skip 判断の根拠に、対話モードでは提示テーブルの推奨度になる。

判定ラベル: ✅ **Yes** (この PR で対応) / ❌ **No** (対応しない、理由明記) / 🤔 **保留** (ユーザー判断が必要・別 PR 推奨)

判定軸 (最低 2 軸を明示する):

| 軸 | Yes 寄り / No・保留 寄り |
|---|---|
| 実害サイズ | 確認済み実害あり / 理論上のみ |
| 修正コスト | 1 箇所完結 / 大規模リファクタ → 保留 |
| 現 PR スコープ適合 | 同一スコープ / 別スコープ → 保留 (別 PR) |
| 変更前から存在 | 本 PR で導入 / 既存問題 → No or 保留 |

実害サイズが不明な場合は妥当な仮定を 1 文添える (例: "Sentry に類似エラーなしの前提")。

**重複指摘の統合**: 同一 path + 近接行 (±5 行以内) + 同一趣旨のコメントは 1 グループにまとめ、判定を 1 回だけ出す。代表は「最高 priority かつ最初の行番号」、他は Reviewer 列に `/` 区切りで併記 (`CodeRabbit / Claude / Devin`)。

---

## 対話モード: Step 5 — 推奨度と修正案つきで提示してユーザーを待つ

ユーザーが**この提示だけを見て 1 ターンで指示を出せる**ことをゴールにする。そのために:

- Value 判定 (推奨度) を全対象に付ける
- Value=Yes / 🤔 保留 の各項目について、**該当ファイルを読んで具体的な修正案を作る** (数行の diff または 1〜2 文の方針。大きい修正は方針のみでよい)
- 読むだけで判断できるよう、修正案には影響範囲 (他に触るファイルの有無) を添える

テーブル形式で提示する。file:line が取れない (API が `line = null` を返す outdated diff など) 場合は `src/foo.ts:?` と表記する。

````
## PR Review Comments Summary

| ID | Priority | Value | Reviewer | File | Summary |
|----|----------|-------|----------|------|---------|
| #1 | 🔴 Must | ✅ Yes | CodeRabbit | src/auth.ts:42 | Null check missing before accessing user.id |
| #2 | 🔴 Must | 🤔 保留 (別 PR) | Devin | src/legacy.ts:15 | SQL injection — ただし変更前から存在 |
| #3 | 🟢 Info | ✅ Yes | Human: alice | src/utils.ts:8 | Unused import statement |

## CI Failures

| Check | Priority | Value | Cause |
|-------|----------|-------|-------|
| lint | 🔴 Must | ✅ Yes | Unused variable in src/api.ts (this PR) |
| e2e | 🟡 Investigate | ❌ No | Timeout only — flaky 判定 3 条件すべて該当、rerun のみ推奨 |

### Details

**#1** 🔴 Must ✅ Yes — CodeRabbit — src/auth.ts:42
> Original comment text here...
Intent: Prevent potential runtime error when user object is undefined
Proposed fix (このファイルのみ):
```diff
- const id = user.id;
+ const id = user?.id ?? null;
```

**#2** 🔴 Must 🤔 保留 — Devin — src/legacy.ts:15
> Original comment text here...
Value Reasoning: 変更前から存在する問題で本 PR スコープ外。別 Issue で追跡を推奨。
````

最後に次アクションを 1 行で促す: `対応する ID を指示してください (例: 「#1 #3 を修正して返信まで」 / 「全部 Yes のとおりに」)`

提示後、ユーザーの判断を待つ。**このモードではここで終了。修正・commit・push・返信は行わない** (ファイルの読み取りは修正案作成のために行ってよい)。

ユーザーが「コメントに返信して」と指示した場合のみ、対応済みコメントに返信する (返信手順・ガイドラインは自律モードの Step 8 と同じ。ただし対象はユーザーが対応済みと確認したコメントのみ)。

---

## 自律モード: Step 6 — 意思決定

各コメント / CI 失敗に対して、Priority と Value 判定に基づきユーザー入力なしで対応を決める:

| Priority | Action |
|----------|--------|
| 🔴 Must | Value=Yes なら修正する。ファイルを読み込み、変更を適用する。 |
| 🟡 Investigate | 明らかに正しく低リスク (Value=Yes) なら修正する。曖昧またはリスクがあればスキップする。 |
| 🟢 Info | 些細で安全な場合 (例: 未使用 import の削除) を除いてスキップする。 |
| ⚫ Skip | 何もしない。Step 9 のレポートに「原因と共に skip した」ことを残す。 |

Value=No / 🤔 保留 のものは Priority に関わらず修正しない (理由を返信とレポートに残す)。

CI 失敗の追加方針:

- lint / format / type check は自動修正コマンド (例: `pnpm lint --fix`, `ruff check --fix`) があればそれを優先し、なければ該当ファイルを直接編集する。
- テスト失敗はログのアサーションとスタックトレースから原因を特定し、プロダクションコード側のバグを修正する。テスト自体の修正はテストの意図が明らかに誤っている場合のみ。
- 同一の run を再実行して直る「だけ」の修正 (`gh run rerun`) は原則行わない。flaky が明確な場合に限り 1 回だけ再実行する。

**修正しない**条件:

- プロダクトやデザインに関する意思決定が必要な変更
- 他の挙動を壊す可能性がある修正
- コメントの意図が不明瞭な場合
- CI 失敗の原因が PR の変更範囲外 (インフラ、シークレット、base ブランチ側の破壊) と判断される場合

## 自律モード: Step 7 — コミットとプッシュ (修正を適用した場合のみ)

`-y` オプションを付けて `/commit` スキルを実行し、その後 `/push` スキルを実行する。

コミットハッシュを参照する返信を投稿する前に、コミットがプッシュ済みであることを確認する:

```bash
git log origin/$(git branch --show-current)..HEAD --oneline
```

未プッシュのコミットが残っていれば、先に `/push` スキルを実行する。

## 自律モード: Step 8 — 各コメントに返信する

処理したすべてのコメントに対して、スレッド返信を投稿する:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments -X POST \
  -f body="{reply}" \
  -F in_reply_to={comment_id}
```

返信ガイドライン:

- 修正した場合はコミットハッシュを参照する (例: "Fixed in abc123.")
- **対応しない場合は、Value 判定の根拠 (スコープ外・既存問題・設計意図との衝突など) を 1〜2 文で具体的に書く**。汎用文言だけで済ませない。
- 返信は簡潔に保つ

| Situation | Reply |
|-----------|-------|
| Fixed | `Fixed in {commit_hash}.` |
| Won't fix | `Keeping current approach: {具体的理由 1〜2 文}.` |
| 保留 (別 PR) | `This predates this PR / is out of scope — tracking separately: {理由}.` |
| Investigated, no change needed | `Investigated — current implementation handles this via {根拠}.` |
| 意図不明瞭 | `Skipping for now — intent is unclear. Please clarify if action is needed.` |
| Info, skipped | `Noted.` |

## 自律モード: Step 8.5 — Devin Review の再キック

PR に Devin (`devin-ai-integration[bot]`) のコメントまたはレビューが 1 件でもある場合のみ実行する。Devin が付いていない PR ではこの Step 全体をスキップする。

### 状態判定

head commit の commit status (`context == "Devin Review"`) で判定する。コメントや review の投稿では判定しない — 指摘ゼロのとき Devin は完了後に何も投稿しない。

```bash
sha=$(gh api repos/{owner}/{repo}/pulls/{pr_number} -q .head.sha)
gh api repos/{owner}/{repo}/commits/$sha/status \
  -q '.statuses[] | select(.context == "Devin Review") | {state, updated_at}'
```

| state | 状態 |
|---|---|
| `pending` | レビュー実行中。`updated_at` から 30 分経過したら Devin 側の失敗とみなし `success` と同じ扱いにする |
| `success` | 完了。コメントが増えていなければ「指摘なし完了」 |
| なし | 未レビューコミット (Devin がまだこの commit を見ていない)。ただし直近の `/devin review` キックが 5 分以内なら反応待ちとして `pending` 扱い (二重キック防止) |

```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate \
  -q '[.[] | select(.body | startswith("/devin review"))] | last | .created_at'
```

### アクション

| 状態 | アクション |
|---|---|
| pending | 何もしない (再キックも停止もしない)。Step 9 で `⏳ Devin Review in progress — waiting.` と報告する |
| なし | `gh pr comment {pr_number} --body "/devin review"` で再キックする |
| `success` | 再キックしない (同じコードの再レビューは無限ループになる)。指摘なし完了なら Step 9 で `✅ Devin Review completed — no issues found.` と報告する |

## 自律モード: Step 9 — レポート

```
✅ Fixed #1, #3 — committed and pushed (abc1234)
⏭️  Skipped #2 (ambiguous), #4 (out of scope — 既存問題)
💬 Replied to #1, #2, #3, #4
🛠  CI: fixed lint (abc1234)
🛠  CI: rerun only (flaky) — e2e
⏭️  CI: skipped deploy-preview — VERCEL_TOKEN not configured
🔁 Kicked Devin Review (push あり)
```

対応すべきコメントも CI 失敗もない場合:

- チェックに `PENDING` が残っている場合: `⏳ No actionable items yet — waiting for pending checks.` と報告する (停止シグナルではない。次の実行を待つ)
- Devin Review が pending の場合 (Step 8.5): `⏳ Devin Review in progress — waiting.` と報告する (停止シグナルではない。次の実行を待つ)
- Devin Review が指摘なしで完了した場合 (Step 8.5): `✅ Devin Review completed — no issues found.` を添えたうえで下の停止シグナルを出す
- 全チェックが完了しており Devin Review も pending でない場合: `✅ No actionable comments or CI failures — PR is mergeable.` (loop 運用時はこれが停止シグナル)
