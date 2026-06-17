---
name: review-pr-by-codex
description: Run the review-pr workflow on Codex instead of Claude — hand the PR number and the review-pr procedure to Codex via the codex:rescue subagent, then surface Codex's integrated review summary. Use when the user wants a PR reviewed by Codex / GPT, or asks to "review this PR with Codex".
disable-model-invocation: true
argument-hint: "[PR番号 | PR URL | 空] [--model <model|spark>] [--effort <...>]"
---

# Review PR by Codex

`@.claude/skills/review-pr/SKILL.md` の手順を **Codex に丸ごと委譲して実行させる** スキル。Claude は forwarder に徹し、差分取得・レビュー・統合サマリー生成は Codex (GPT) 側で行わせる。最後に Codex の出力をそのままユーザーに提示する。

```
引数解析 → review-pr 手順の読み込み → Codex 用タスクプロンプト合成 → codex:rescue へ委譲 → Codex 出力を verbatim 提示
```

Claude 自身は reviewer agent を起動しない (それは `/review-pr` の役割)。本スキルは「同じレビューを Codex の目で実施させたい」とき専用。

## 引数

$ARGUMENTS

`--model` / `--effort` / `--resume` / `--fresh` が含まれていれば Codex のランタイム制御フラグなのでタスク本文から切り離し、`codex:rescue` への委譲時にそのまま付与する。残りを PR 指定として扱う。

PR 指定の優先順は review-pr と同一:
1. **PR番号** (`^#?\d+$`)
2. **PR URL** (`github.com` を含む) → 番号抽出
3. **引数なし** → 現ブランチから自動検出 (Codex 側に検出させる)

## 手順

### 1. review-pr の手順を読み込む

`@.claude/skills/review-pr/SKILL.md` の本文を読み込む。さらに同ディレクトリの参照ファイル (`output-format.md` 等) も読み込み、Codex が単体で完結できるよう全文をタスクプロンプトに埋め込む。

- reviewer agent 一覧の観点 (`code-reviewer` / `security-reviewer` / `typescript-reviewer` / `postgres-reviewer`) は **Claude のサブエージェントなので Codex からは起動できない**。Codex には「これらの観点を 1 人で順に当てる」よう指示に変換する (観点名そのものではなく、各行の『一次責任』列の内容を観点リストとして渡す)。

### 2. Codex 用タスクプロンプトを合成する

以下の構成で 1 本のプロンプトにまとめる:

```
あなたは GitHub PR のレビュアーです。以下の手順書に従って PR <PR指定> をレビューし、
統合サマリーを Markdown で出力してください。差分取得・既存コメント取得には `gh` を使ってよい。

## 制約
- これは読み取り中心のレビュータスク。コード修正・コミット・push はしない。
- Pending Review の投稿 (手順書 Phase 5) は **実行しない**。投稿は対話確認が必要で、
  この委譲では行わない。Phase 1〜4 (情報収集→トリガー評価→集約→統合サマリー) までを実施し、
  Findings テーブルまで含む統合サマリーを stdout に出力して終了する。
- 手順書中の「reviewer agent を並列起動」は Claude 固有機構。あなたは単一エージェントとして、
  各観点 (品質/設計, セキュリティ, 型安全性, Postgres) を順に自分で当てること。
  TS/JS 差分がなければ型安全性観点は省略、DB 記述がなければ Postgres 観点は省略してよい。

## review-pr 手順書 (全文)
<review-pr/SKILL.md 本文>

## 出力フォーマット
<review-pr 配下の output-format 等の本文>
```

PR 指定が「引数なし」の場合は、プロンプト内で「現在のブランチに対応する PR を `gh pr view` で自動検出してからレビューせよ」と指示する。

### 3. codex:rescue へ委譲する

合成したプロンプトを `codex:rescue` スラッシュコマンド (= `codex:codex-rescue` サブエージェント) に渡して実行させる。

- レビューは読み取り中心なので **read-only で実行させる**。`codex:rescue` のデフォルトは write-capable (`task --write`) だが、本スキルでは委譲時に「read-only でよい / 修正は不要」と明示し、`--write` を付けさせない (companion の `task` は `--write` 無しで read-only サンドボックスになる)。
- 引数で受け取った `--model` / `--effort` / `--resume` / `--fresh` があれば一緒に渡す。
- `codex:rescue` の作法に従い、Codex の stdout は **整形・要約せずそのまま** ユーザーに提示する。

委譲は `codex:rescue` 経由とし、`codex-companion.mjs` を直接叩かない (setup チェック・resume 判定・forwarder 契約は rescue 側が担う)。Codex 未セットアップ/未認証なら rescue 側が `/codex:setup` を案内する。

### 4. 投稿が必要なとき (任意)

Codex の統合サマリーを見たうえでユーザーがインラインコメント投稿を望む場合は、`/review-pr` (Claude 版) の Phase 5 に引き継ぐ。本スキルは投稿しない。

## review-pr 本家との違い

| | `/review-pr` | `/review-pr-by-codex` |
|---|---|---|
| レビュー実行主体 | Claude サブエージェント (並列) | Codex (単一エージェント) |
| Pending Review 投稿 | する (対話確認あり) | しない (Phase 4 まで) |
| 観点の分担 | エージェント一覧で分離 | Codex が 1 人で順に当てる |
| 用途 | 通常の PR レビュー | Codex/GPT の視点でのセカンドオピニオン |
