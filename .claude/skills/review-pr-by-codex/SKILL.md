---
name: review-pr-by-codex
description: Delegate a GitHub PR review to Codex via codex:rescue when the user requests a Codex/GPT review.
argument-hint: "[PR番号 | PR URL | 空] [--model <model|spark>] [--effort <...>]"
---

# Review PR by Codex

引数: $ARGUMENTS。`--model` / `--effort` / `--resume` / `--fresh` はタスク本文から分離し、そのまま `codex:rescue` に渡す。残りはPR番号またはURL。省略時はCodex側で現在のブランチから検出させる。URLの対象リポジトリも保持する。

1. [review-pr](../review-pr/SKILL.md) の引数・エージェント一覧・Phase 1〜4と、[output-format.md](../review-pr/output-format.md) を読み、委譲プロンプトに内容を埋め込む。`posting.md` は読まない。
2. 並列reviewer起動の指示を、Codexが単独で該当観点を順にレビューする指示へ置き換える。観点・適用条件・一次責任は正本の表から取得し、ここで別管理しない。呼び出し元もreviewerを起動しない。
3. PR指定と次の制約を添え、`codex:rescue` (`codex:codex-rescue` サブエージェント) に委譲する。
   - **read-only、`--write` なし**。`gh` による情報取得は可。コード修正・コミット・push・コメント投稿は禁止。
   - Phase 1〜4まで実行し、指摘表を含む統合サマリーをstdoutへ出して終了する。Phase 5は実行しない。
4. Codexのstdoutを整形・要約せず提示する。ユーザーが投稿を希望した場合だけ、`review-pr` のPhase 5へ引き継ぐ。

`codex-companion.mjs` を直接実行しない。セットアップ・認証・resumeの扱いはrescue側に委ねる。
