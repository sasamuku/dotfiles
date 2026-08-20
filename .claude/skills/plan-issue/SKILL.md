---
name: plan-issue
description: Create or update the execution plan for a GitHub issue and always sync it to the issue comment. Reads the issue deeply (epic/siblings/PRs) on first run; reflects conversation decisions and sub-issue progress on updates.
argument-hint: <issue-number>
---

# Plan Issue

GitHub Issue の実行計画を作成・更新し、**必ず Issue コメントへ同期して終わる** (同期は手動ステップではなく事後条件)。

## 計画ファイルの置き場所 (規約)

```
~/.claude/plans/<owner>/<repo>/issue-<issue-number>.md
```

- リポジトリの外に置くため git と無縁 (コンフリクト・コミット混入が起きない)
- 絶対パスなので worktree・セッションをまたいで同じファイルを参照できる
- 正本は Issue の同期コメント (PLANS_SYNC_MARKER)。ローカルファイルは作業コピー

パス解決:

```bash
REPO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')
PLAN_FILE="$HOME/.claude/plans/$REPO/issue-<issue-number>.md"
mkdir -p "$(dirname "$PLAN_FILE")"
```

## 引数

GitHub Issue 番号 (例: `123` または `#123`) または Issue の URL。

$ARGUMENTS

Issue 番号の解決順: 引数 → 会話文脈で扱っている Issue → `~/.claude/plans/$REPO/` 内のファイルが 1 つだけならそれ → 特定できなければユーザーに確認。

**Issue は必須**。Issue の参照がどこからも得られない場合は計画を作らず、次を案内する:

```
計画は Issue に紐づけて管理します。先に Issue を作成してください:
  /create-issue <タイトル・概要>
作成後、/plan-issue <issue-number> で計画を作成できます。
```

ユーザーが望めば、その場で `/create-issue` スキルのワークフローに従って Issue を作成し、続けて計画作成に進んでよい。

## モード判定

`$PLAN_FILE` が存在すれば**更新モード**、存在しなければ Issue 側の同期コメントを確認する (同期セクションの検索コマンド)。同期コメントが**ある**場合は別マシン・過去セッションで作られた計画なので、その本文にフロントマター (issue / issue_url / last_synced) を付与して `$PLAN_FILE` に取り込んでから**更新モード**に入る (新規作成して既存計画を黙って上書きしない)。どちらもなければ**新規作成モード**。

## 新規作成モード

1. `/read-issue` スキルのワークフローに従い、Issue を深く読む (親 Epic・兄弟 Issue・実装 PR まで)
2. 必要に応じてコードベースから関連ファイルを検索する
3. 計画のプレビューを提示し、**ユーザー承認 (y/n) を得る** — ここが人間の唯一のゲート
4. 承認後、フロントマター付きで `$PLAN_FILE` に書き出し、同期する (後述)

## 更新モード

会話での決定事項・レビュー結果・サブ Issue の進捗 (`gh issue view <n> --json subIssues` → 各サブ Issue の state) を計画に反映する:

- **Validation & Acceptance Criteria**: 完了項目にチェック
- **Open Questions**: 解決済みの問いを削除 (決定は Decision Log へ)
- **Decision Log**: 下された判断を日付付きで追記
- **Discoveries & Insights / Follow-up Issues**: 新たな発見・課題を追記
- 既存の構造・ナラティブは維持し、新しいセクションを追加しない

更新に**承認は不要** (会話自体が合意)。反映後、必ず同期する。

## 同期 (両モード共通・省略不可)

1. 既存の同期コメントを検索 (`{owner}/{repo}` は gh api がカレントリポジトリから自動解決する。`$ISSUE` はこちらで埋める):

```bash
COMMENT_ID=$(gh api "repos/{owner}/{repo}/issues/$ISSUE/comments" \
  --jq '[.[] | select(.body | contains("PLANS_SYNC_MARKER"))][0].id')
```

(複数ヒットした場合は最初の 1 件のみを同期先とし、他は触らない)

2. 本文を組み立て、更新 (PATCH) または新規投稿:

```bash
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BODY=$(awk 'f; /^---$/{c++; if(c==2) f=1}' "$PLAN_FILE")  # フロントマターを行数非依存でスキップ
CONTENT="<!-- PLANS_SYNC_MARKER:${TIMESTAMP} -->

$BODY"

# COMMENT_ID あり
gh api -X PATCH "repos/{owner}/{repo}/issues/comments/$COMMENT_ID" -f body="$CONTENT"
# なし
gh issue comment "$ISSUE" --body "$CONTENT"
```

3. `$PLAN_FILE` の `last_synced` を同タイムスタンプに更新
4. 完了表示: `✓ Plan synced to issue #<n> (<PLAN_FILE>)`

## Frontmatter

```yaml
---
issue: 123
issue_url: https://github.com/owner/repo/issues/123
last_synced: 2025-11-12T10:30:00Z
---
```

## 計画の構成

1. **Purpose / Overview** — ゴール・価値・解決する問題
2. **Context & Direction** — 背景・設計思想・主要な制約
3. **Validation & Acceptance Criteria** — テスト可能な受け入れ基準 (チェックボックス)
4. **Specification** — 仕様・アーキテクチャ決定・設計詳細
5. **Open Questions** — 未解決の問い・ブロッカー
6. **Discoveries & Insights** — 技術的発見・学び
7. **Decision Log** — 日付付きの判断と根拠
8. **Outcomes & Retrospectives** — 結果と振り返り
9. **Follow-up Issues** — 後続タスク・対象外・技術的負債

## ガイドライン

- 簡潔さと網羅性を両立し、継続的に更新される「生きたドキュメント」として整形する
- 追跡可能なタスクには Markdown チェックボックス (`- [ ]`) を使う
