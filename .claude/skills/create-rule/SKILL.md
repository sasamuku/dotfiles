---
name: create-rule
description: .claude/rules/ 配下のルールファイル (*.md) を新規作成・編集するときに、適切なメカニズム選択と paths スコープを保証する。ルールを書く前・書いた後に必ず適用する。
when_to_use: .claude/rules/ にルールファイルを新規作成するとき、既存のルールファイルを編集するとき、「ルールを追加して」「規約を書いて」と言われたとき、ルールが全タスクで常時注入されていることに気づいたとき。
---

# Create Rule

`.claude/rules/` のルールはコンテキストに注入される指示。書き方を誤ると無関係な作業でトークンを浪費し、モデルの判断を曇らせる。作成・編集のたびに次の手順を踏む。

## STEP 0: そもそも rules が適切か判断する

書こうとしている内容を、まず置き場所で振り分ける。**rules に何でも書かない。**

| 内容 | 置き場所 |
|---|---|
| 全セッションで常に効かせたい事実 (ビルドコマンド・プロジェクト構成・全体規約・応答トーン) | `CLAUDE.md` |
| 特定のファイル種別・ディレクトリにだけ効かせたい指示 | **`.claude/rules/` (paths スコープ)** |
| 手順もの・呼び出し時だけ要る重い知識 (デプロイ・コミット・コード生成) | skill ([/en/skills](https://code.claude.com/docs/en/skills)) |
| Claude の判断に関係なく確実にブロック/強制したい挙動 | PreToolUse hook ([/en/hooks-guide](https://code.claude.com/docs/en/hooks-guide)) |

rules と CLAUDE.md は **context であって enforcement ではない** — 「決して X するな」を確実に止めたいなら hook にする。

## STEP 1: ファイルを分ける

- **1 ファイル 1 トピック。** 記述的なファイル名にする (`testing.md`, `api-design.md`, `security.md`)。
- 数が増えるなら `frontend/`・`backend/` 等のサブディレクトリに分けてよい (再帰探索される)。

## STEP 2: paths でスコープする

`paths` の無いルールは **全タスクで無条件ロード** (`.claude/CLAUDE.md` と同優先度)。範囲が「全ファイル共通」でない限り、必ず `paths` フロントマターをファイル先頭に置く。

```yaml
---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
---
```

- glob 形式。`**` = 任意階層、`*` = 単一階層。拡張子は brace expansion `{ts,tsx,...}` で 1 行にまとめる (1 拡張子 1 行に分けない)。
- マッチするファイルを **Claude が読むとき** に発火する (毎 tool use ではない)。
- 迷ったらスコープする (狭すぎる害は小さいが、広すぎるとコンテキストを汚す)。

### 適用範囲ごとの推奨 paths (出発点。実態に合わせて増減)

| 適用範囲 | paths |
|---|---|
| TS/JS 全般 | `**/*.{ts,tsx,js,jsx,mjs,cjs}` |
| Web 系言語 + SQL (セキュリティ系) | `**/*.{ts,tsx,js,jsx,mjs,cjs,py,rb,go,php,sql}` |
| API ハンドラ等の限定領域 | `src/api/**/*.ts` `**/*.handler.ts` のようにディレクトリ/命名で絞る |
| Python のみ | `**/*.py` |
| 全ファイル共通 (規約・トーン等) | **`paths` を付けない** |

## STEP 3: 整合と検証

- **本文と paths が一致しているか確認** — 本文が `z.object`・`console.log` 禁止など TS/JS 前提なのに `paths` が空、といった不整合がないこと。
- **既存ルール編集時は先頭の `paths` を確認** — 無ければ常時注入が妥当か判断し、不要なら追加する。
- **`/memory` でロード状況を確認** (デバッグには `InstructionsLoaded` hook も使える)。

## 補足: 共有とユーザーレベル

- **symlink でルールを共有できる** (複数プロジェクトに同じルールをリンク):
  ```bash
  ln -s ~/shared-claude-rules .claude/rules/shared
  ln -s ~/company-standards/security.md .claude/rules/security.md
  ```
- **`~/.claude/rules/`** は全プロジェクトに効くユーザーレベルルール (プロジェクトルールより先にロードされ、プロジェクト側が優先)。プロジェクト非依存の個人設定向け。

## 参考

- 一次情報: [How Claude remembers your project — Organize rules with .claude/rules/](https://code.claude.com/docs/en/memory.md)
- 設計の背景: [Claude Code を操る — Skills, Hooks, Rules, Subagents](https://claude.com/ja/blog/steering-claude-code-skills-hooks-rules-subagents-and-more)
