# Claude Code

変更する機能の公式資料だけ確認する。

| 対象 | 配置・注意点 | 公式資料 |
|---|---|---|
| 指示 | `CLAUDE.md`、`.claude/rules/*.md`。個人共通は `~/.claude/`。限定的なルールには `paths` を付ける | [Memory](https://code.claude.com/docs/en/memory) |
| スキル | `.claude/skills/<name>/SKILL.md`、個人共通は `~/.claude/skills/` | [Skills](https://code.claude.com/docs/en/skills) |
| hook・権限 | `.claude/settings.json`、個人用の `.claude/settings.local.json`、`~/.claude/settings.json`。既存の設定階層を維持する | [Hooks](https://code.claude.com/docs/en/hooks)、[Settings](https://code.claude.com/docs/en/settings) |
| サブエージェント | `.claude/agents/*.md` または `~/.claude/agents/` | [Subagents](https://code.claude.com/docs/en/sub-agents) |

ルールの例:

```yaml
---
paths:
  - "src/**/*.{ts,tsx}"
---
```

`paths` がないルールは常時読み込まれる。本文と対象を一致させ、YAMLの誤りでスコープが外れないか確認する。`/memory` やデバッグ出力で読み込みを確認する。

スキルの起動制御は用途に合わせる。`disable-model-invocation: true` は手動のみ、`user-invocable: false` はモデルのみ。`context: fork` や `allowed-tools` は必要な場合だけ指定し、Codexにも同じ効果があるとは扱わない。

hookはイベントごとにブロック可否と出力仕様が異なる。判定結果・診断出力を混ぜず、実際の起動条件と作業ディレクトリで検証する。
