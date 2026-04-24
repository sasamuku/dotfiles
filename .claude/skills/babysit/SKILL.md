---
name: babysit
description: Autonomously triage PR review comments and CI failures, apply necessary fixes, commit, push, and reply to comments. Designed for use with /loop 5m /babysit to continuously babysit PRs.
allowed-tools: Bash(git *), Bash(gh *), Read, Edit, Write
---

# PR の自動管理 (Babysit)

PR の自律的なメンテナンスループ。レビューコメントと CI ステータスをトリアージし、必要に応じて修正を適用し、対応済みコメントへの返信を行う。ユーザー操作は不要で、完全自律で動作する。

## ワークフロー

### Step 1: 現在の PR を検出する

```bash
gh pr view --json number,headRepository,state -q '{number: .number, owner: .headRepository.owner.login, repo: .headRepository.name, state: .state}'
```

- 現在のブランチにオープンな PR がなければ、静かに終了する。
- state が `MERGED` または `CLOSED` であれば、`✅ PR is merged/closed. Stopping.` と出力して終了する。

### Step 2: 未解決のレビューコメントを取得する

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  --jq '[.[] | select(.in_reply_to_id == null)] as $roots
    | [.[] | .in_reply_to_id] as $replied
    | $roots | map(select(.id as $id | $replied | index($id) | not))'
```

これで「スレッドのルートコメント」かつ「誰からも返信されていない」ものだけが残る。結果が空ならこのステップはスキップして Step 3 へ進む。

### Step 3: CI の失敗を取得する

**Step 2 の結果 (コメント有無) に関わらず常に実行する。**

```bash
gh pr checks {pr_number} --json name,state,link -q '.[] | select(.state == "FAILURE")'
```

- 結果が空ならこのステップはスキップする (すべて pass / pending)。
- 失敗があれば、各 `link` の末尾の数値 (run_id) を抽出し、ジョブログを取得する:

  ```bash
  run_id=$(echo "{link}" | grep -oE '[0-9]+$')
  gh run view "$run_id" --log-failed
  ```

  `link` が無い場合のフォールバック:

  ```bash
  gh run list --branch "$(git branch --show-current)" --json databaseId,conclusion \
    -q '.[] | select(.conclusion == "failure") | .databaseId' | head -1
  ```

### Step 4: 各コメント / CI 失敗を分類する

各コメントに優先度を割り当てる:

- 🔴 **Must** — バグ、セキュリティ問題、破壊的変更
- 🟡 **Investigate** — 変更が必要かどうか判断が必要なもの
- 🟢 **Info** — スタイル提案、細かい指摘

CI の失敗はログから原因を特定して分類する:

- 🔴 **Must** — lint / format / type check / テスト失敗で、原因がこの PR の変更に明確に帰属するもの
- 🟡 **Investigate** — flaky テストの疑い、外部依存 / ネットワーク起因の可能性があるもの
- ⚫ **Skip** — インフラ障害、シークレット不足など PR の変更では直せないもの

flaky の判定は次を全て満たしたときに「明確」とみなす:
- ログにプロダクションコード由来のアサーション失敗 / 例外が**ない** (タイムアウト・ネットワーク系のみ)
- 同一テストが main / base ブランチの直近 run で成功している
- 直近 10 run の履歴で 2 回以上成功している

### Step 5: 自律的な意思決定

各コメント / CI 失敗に対して、ユーザー入力なしで判断して対応する:

| Priority | Action |
|----------|--------|
| 🔴 Must | 修正する。ファイルを読み込み、変更を適用する。 |
| 🟡 Investigate | 明らかに正しく低リスクなら修正する。曖昧またはリスクがあればスキップする。 |
| 🟢 Info | 些細で安全な場合 (例: 未使用 import の削除) を除いてスキップする。 |
| ⚫ Skip | 何もしない。Step 9 のレポートに「原因と共に skip した」ことを残す。 |

CI 失敗の追加方針:
- lint / format / type check は自動修正コマンド (例: `pnpm lint --fix`, `ruff check --fix`) があればそれを優先し、なければ該当ファイルを直接編集する。
- テスト失敗はログのアサーションとスタックトレースから原因を特定し、プロダクションコード側のバグを修正する。テスト自体の修正はテストの意図が明らかに誤っている場合のみ。
- 同一の run を再実行して直る「だけ」の修正 (`gh run rerun`) は原則行わない。flaky が明確な場合に限り 1 回だけ再実行する。

**修正しない**条件:
- プロダクトやデザインに関する意思決定が必要な変更
- 他の挙動を壊す可能性がある修正
- コメントの意図が不明瞭な場合
- CI 失敗の原因が PR の変更範囲外 (インフラ、シークレット、base ブランチ側の破壊) と判断される場合

### Step 6: コミットとプッシュ (修正を適用した場合のみ)

`-y` オプションを付けて @.claude/skills/commit/SKILL.md を実行し、その後 @.claude/skills/push/SKILL.md を実行する。

### Step 7: 返信前にプッシュを確認する

コミットハッシュを参照する返信を投稿する前に、コミットがプッシュ済みであることを確認する:

```bash
git log origin/$(git branch --show-current)..HEAD --oneline
```

コミットがまだプッシュされていなければ、先に @.claude/skills/push/SKILL.md を実行する。

### Step 8: 各コメントに返信する

処理したすべてのコメントに対して、自律的に返信を投稿する:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -X POST -f body="{reply}"
```

返信テンプレート:

| Situation | Reply |
|-----------|-------|
| Fixed | `Fixed in {commit_hash}.` |
| Won't fix — ambiguous | `Skipping for now — intent is unclear. Please clarify if action is needed.` |
| Won't fix — risky | `Keeping current approach to avoid unintended side effects.` |
| Investigated, no change needed | `Investigated — current implementation handles this correctly.` |
| Info, skipped | `Noted.` |

### Step 9: レポート

CI のレポート行テンプレート:

| 状況 | テンプレ |
|---|---|
| Must 修正済み | `🛠 CI: fixed {check_name} ({commit_hash})` |
| Flaky 判定で rerun のみ | `🛠 CI: rerun only (flaky) — {check_name}` |
| Skip | `⏭️  CI: skipped {check_name} — {reason}` |

```
✅ Fixed #1, #3 — committed and pushed (abc1234)
⏭️  Skipped #2 (ambiguous), #4 (risky)
💬 Replied to #1, #2, #3, #4
🛠  CI: fixed lint (abc1234)
⏭️  CI: skipped deploy-preview — VERCEL_TOKEN not configured
```

対応すべきコメントも CI 失敗もない場合: `✅ No actionable comments or CI failures found.`
