---
name: create-pr
description: Create a GitHub pull request using gh CLI, following the repository's own PR template and language conventions
disable-model-invocation: true
---

# Create PR

gh CLI を使ってプルリクエストを作成する汎用スキル。**言語・セクション構成・セクション見出し・特殊コメント（Copilot 指示など）は、すべてリポジトリ側の PR テンプレートと慣習に従う**。スキル自身は書き方を固定しない。

## 前提の収集

PR 作成の前に以下を確認する。

1. **PR テンプレートの実在と中身**:
   ```bash
   cat .github/pull_request_template.md 2>/dev/null || \
   cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || \
   ls .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null
   ```
   - テンプレートが**ある**なら、そのセクション構成・見出しをそのまま使う。コメント (`<!-- ... -->`) の指示も保持する。
   - テンプレートが**ない**なら、`gh pr list --state all --limit 5 --json title,body` で直近の PR を見て慣習的なフォーマットを推定する。
   - どちらも見つからなければ下記の**最小構成**で作る:

     ```markdown
     ## Summary

     <!-- この PR で何を変えたかを 1〜3 文で -->

     ## Test Plan

     - [ ] <確認した動作 1>
     - [ ] <確認した動作 2>
     ```

     これを既定とし、リポジトリの特性に応じて `## Notes` や `## Screenshots` を追加してよい。

2. **言語の選択**（以下の優先順）:
   1. テンプレート本体と同じ言語（テンプレートが日本語なら日本語、英語なら英語）
   2. 直近 PR 本文の多数派の言語
   3. リポジトリの `CLAUDE.md` / `AGENTS.md` / `CONTRIBUTING.md` に言語指定があれば従う
   4. 上記いずれでも判断できなければユーザーに確認
   - **タイトルと本文は原則同じ言語で揃える**。Conventional Commits の `type(scope):` プレフィックスは英語のまま残してよい（例: `fix(auth): ログインリダイレクトを修正`）。

3. **ブランチ・コミット・差分の把握**:
   ```bash
   git branch --show-current
   git log <base>..HEAD --oneline
   git diff <base>...HEAD --stat
   ```
   `<base>` は通常 `main`（`gh repo view --json defaultBranchRef --jq .defaultBranchRef.name` で確認可能）。

## 作成手順

1. **ブランチを push**（upstream 未設定の場合）:
   ```bash
   git push -u origin <branch>
   ```

2. **PR 本文を用意**:
   - テンプレートがあれば `cp .github/pull_request_template.md /tmp/pr-body.md` してから編集する。**`cp` は最初の 1 回のみ**。`/tmp/pr-body.md` を編集後に上書きしないこと。
   - 各セクションに情報を埋める。空セクションでも "N/A" を入れて**省略しない**（テンプレート遵守のため）。
   - テンプレート内の HTML コメントは下記「テンプレート遵守の鉄則」の分類に従って扱う（bot 制御は保持、自由記述ガイドは記述後に削除してよい）。

3. **PR 作成**:
   ```bash
   gh pr create --draft \
     --title "type(scope): 簡潔なタイトル" \
     --body-file /tmp/pr-body.md \
     --base <base>
   ```
   - 本文が単純なら `--body` でもよいが、改行・コードブロックを含むならファイル経由が安全。
   - **原則ドラフト** (`--draft`) で作成する。完成したら `gh pr ready <N>` で切り替える。

4. **確認**:
   ```bash
   gh pr view <N> --json title,body,isDraft,url
   ```

## タイトル規約

- Conventional Commits (`type(scope): subject`) を既定とする。絵文字なし。
- `type`: `feat` / `fix` / `docs` / `chore` / `refactor` / `style` / `test` / `perf` / `build` / `ci`
- ただし**リポジトリの既存 PR タイトルに別の慣習が強く見られる場合はそれに従う**（例: チケット番号プレフィックス・絵文字ありの運用）。
- タイトルの**本文部分**は本文と同じ言語で書く (日本語運用の repo なら日本語)。`type(scope):` は英語のまま。

## テンプレート遵守の鉄則

- **見出しをリネームしない**（Copilot / pr_agent / Dependabot 等の bot がセクション名を正規表現でパースしている可能性がある）。
- **テンプレートにないセクションを追加しない**。追加情報は既存セクション内に収める。
- **全セクションを埋める**。内容がなければ "N/A" / "なし" 等を入れる。

### HTML コメントの 2 分類

テンプレ内 HTML コメントは次の 2 種に分けて扱う。

**Type 1: bot 制御コメント（絶対に削除・改変しない）**

bot やレビュアーへの指示、自動補完用マーカー、保持指示が書かれているもの。例:

- `<!-- GitHub Copilot コードレビューへの指示: ... -->` — Copilot へのレビュー指示
- `<!-- pr_agent:summary -->` / `<!-- pr_agent:walkthrough -->` — pr_agent の自動補完マーカー
- `<!-- copilot:summary -->` — Copilot 自動補完マーカー
- `<!-- Please do NOT remove this template. -->` — 明示的な保持指示
- `<!-- Dependabot ... -->` — bot 用設定

これらが**セクション内の唯一の内容**である場合、コメントだけ残して人間は書き足さない（上の「全セクションを埋める」はこの種のコメントで既に埋まっていると判断してよい）。

**Type 2: 自由記述ガイドコメント（人間が記述したら削除してよい）**

セクションの書き方を読み手に教えるためのガイド文。例:

- `<!-- なぜを端的に説明してください -->`
- `<!-- 何を見てほしくてレビュー依頼しているか -->`
- `<!-- Briefly explain what changed and why. -->`
- `<!-- How was this verified? -->`

これらは**人間が本文を書いたら削除する**。残すと PR 表示で本文の上下に冗長なコメントが並んで読みにくくなる（HTML コメントは GitHub UI 上では非表示だが、PR 編集画面・差分には残る）。

**判別基準**: bot 名や保持指示が含まれていれば Type 1、書き方の説明・例示・問いかけのみなら Type 2。**迷ったら Type 1 として保持する**（誤削除より誤保持のほうが安全）。

## 言語切り替え時の注意

- タイトルを途中で英語→日本語に切り替えた場合、**本文も同じ言語に揃え直す**。混在はレビュアーに読みづらい。
- ユーザーが「本文を日本語に」と指示したら、タイトルもその言語に合わせるか確認する。逆も同じ。

## よく使う gh CLI コマンド

```bash
gh pr list --author "@me"                         # 自分が開いた PR
gh pr status                                       # 現ブランチに紐づく PR 状態
gh pr view <N>                                    # PR の詳細
gh pr view <N> --json title,body                  # タイトル・本文を JSON で取得
gh pr edit <N> --title "..." --body-file ...      # 後から編集
gh pr edit <N> --add-reviewer user1,user2         # レビュアー追加
gh pr ready <N>                                   # Draft → Ready
gh pr checks <N>                                  # チェック状況
gh pr merge <N> --squash                          # マージ (必要なら --auto)
```

## ありがちなミス

- **テンプレートを読まずに PR を作る** → 見出しが独自になり bot が動かない。必ず `cat` してから埋める。
- **言語を固定してしまう** → 日本語運用 repo で英語本文を生成。テンプレとコメントから判定する。
- **HTML コメントを消す** → `<!-- Copilot ... -->` を含むコメントは bot 制御なので保持する。
- **空セクションを省略** → テンプレの構成が崩れる。"N/A" で残す。
- **タイトルと本文の言語不一致** → レビュアー体験を損なう。揃える。
- **`--body` でヒアドキュメント・改行を直接渡す** → シェルエスケープで壊れることがある。複雑な本文は `--body-file` で。
- **ドラフトを経ずにいきなり Ready で作る** → 誤作成時の取り消しコストが高い。原則 `--draft`。
