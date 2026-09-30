---
name: plan-issue
description: Create or update an issue execution plan and sync it to the issue comment.
argument-hint: <issue-number>
---

# Plan Issue

引数: $ARGUMENTS (Issue番号・URL)。解決順は引数→会話→対象リポジトリの計画ファイルが1件ならそれ→確認。Issue不明なら計画を作らず `/create-issue` を案内する。作成が依頼された場合は起票後に続ける。
URLのowner/repoを含め対象を解決し、以後の `gh` 操作で明示する。

## 正本・モード

正本はIssueの `PLANS_SYNC_MARKER` コメント。作業コピーは `~/.claude/plans/<owner>/<repo>/issue-<N>.md`。フロントマターは `issue`・`issue_url`・`last_synced`。

- 作業コピーがあれば更新モード。
- なければ同期コメントを確認し、あれば本文とフロントマターを取り込んで更新する。両方なければ新規作成。既存計画を新規計画で上書きしない。

## 作成・更新

新規は [read-issue](../read-issue/SKILL.md) の `--full` で親・兄弟・実装PRまで読み、関連コードを調べる。プレビューを提示し、ユーザー承認後に作業コピーを書き出す。

更新は会話の決定・レビュー結果・子Issueの状態を反映し、再承認は不要。完了した受け入れ基準にチェックし、解決した問いはDecision Logへ移す。発見・後続課題・日付付きの判断を記録する。既存構造を保ち、節を追加しない。

新規計画の構成:

1. Purpose / Overview: 目的・価値
2. Context & Direction: 背景・制約
3. Validation & Acceptance Criteria: 検証可能な受け入れ基準 (`- [ ]`)
4. Specification: 仕様・設計
5. Open Questions: 未解決事項
6. Discoveries & Insights: 発見
7. Decision Log: 日付・判断・根拠
8. Outcomes & Retrospectives: 結果・振り返り
9. Follow-up Issues: 後続・対象外

## 同期 (両モード必須)

対象Issueのコメントから `PLANS_SYNC_MARKER` を含む同期先を検索する。複数あれば最初の1件だけ更新し、他は触らない。

```bash
COMMENT_ID=$(gh api "repos/<owner>/<repo>/issues/$ISSUE/comments" --paginate \
  --jq '[.[] | select(.body | contains("PLANS_SYNC_MARKER"))][0].id')
```

ページをまたいで複数見つかった場合も最初の1件を選ぶ。
作業コピーのフロントマターを除いた本文に `<!-- PLANS_SYNC_MARKER:<UTC時刻> -->` を付け、一時ファイルへ保存する。

- 同期先あり: `gh api -X PATCH repos/<owner>/<repo>/issues/comments/<id>` へJSONの `body` として `--input` で送る。
- 同期先なし: `gh issue comment <N> --repo <owner>/<repo> --body-file <file>` で投稿する。

同期成功後だけ `last_synced` を同じ時刻に更新し、Issueへのリンクと作業コピーの場所を報告する。失敗時は作業コピーを保持して未同期と報告し、完了扱いしない。
