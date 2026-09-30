# Codex

CLI・アプリなど利用環境とバージョンを確認する。利用可能なら `openai-docs` を使い、変更する機能の公式資料だけ確認する。

| 対象 | 配置・注意点 | 公式資料 |
|---|---|---|
| 指示 | `AGENTS.md`、個人共通は `~/.codex/AGENTS.md`。階層と `AGENTS.override.md` の有無を確認する | [Instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md) |
| スキル | `.agents/skills/<name>/SKILL.md`、個人共通は `~/.agents/skills/`。既存の管理元・symlinkを尊重する | [Skills](https://learn.chatgpt.com/docs/build-skills) |
| 実行ルール | `.rules` の `prefix_rule()`。文章規約はここに書かない | [Rules](https://learn.chatgpt.com/docs/agent-configuration/rules) |
| hook | 設定階層の `hooks.json` または `config.toml` の `[hooks]`。同じ階層で表現を重複させない | [Hooks](https://learn.chatgpt.com/docs/hooks) |
| サブエージェント | `.codex/agents/*.toml`。既存の登録方法と対応形式を確認する | [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) |
| 権限・その他設定 | `~/.codex/config.toml`、`.codex/config.toml`。管理側の制約・プロジェクトの信頼状態も確認する | [Configuration](https://learn.chatgpt.com/docs/config-file/config-basic) |

Claudeの `paths` 付きルールを `AGENTS.md` にコピーしても同じスコープにはならない。指示の探索階層と作業ディレクトリに合わせて配置する。

実行ルールは対象コマンドの許可・確認・禁止を扱う。広いprefixで意図せず許可範囲を拡げず、`codex execpolicy check` で対象・対象外のコマンドを検証する。

hookは導入済みバージョンの対応イベント・ハンドラ形式・有効化条件を確認してから作る。Claudeのhook設定や終了コードの意味を流用しない。
