---
name: create-skill
description: Create a new Claude Code skill with best practices. Use when user wants to create a skill, add a SKILL.md, or extend Claude's capabilities.
disable-model-invocation: true
allowed-tools: Read, Write, Bash(mkdir *), WebFetch
---

# Create Skill

公式のベストプラクティスに従って、Claude Code の新しいスキルを作成する。

## 入力
`$ARGUMENTS`

## プロセス

1. **最新ドキュメントを取得する**
   まず公式の Skills ドキュメントを読む:
   ```
   WebFetch: https://code.claude.com/docs/en/skills
   ```

2. **ユーザーの意図を把握する**
   - 入力からスキル名と目的を推測する
   - スキル名: 小文字とハイフンのみ (最大 64 文字)
   - ユーザー起動か、モデル起動か、あるいは両方かを決める

3. **スキル種別を決める**
   - **Reference**: 背景知識 (規約、パターン、ドメイン情報)
   - **Task**: 手順化されたワークフロー (デプロイ、コミット、コード生成など)

4. **スキルディレクトリと SKILL.md を作成する**
   - 配置場所: `.claude/skills/<skill-name>/SKILL.md`
   - 先にディレクトリを作成し、次に SKILL.md を作成する

## 重要な判断ポイント

### 起動制御
| 設定 | 効果 |
|------|------|
| (既定) | ユーザーも Claude も起動可能 |
| `disable-model-invocation: true` | ユーザーのみ起動可能 (副作用ありの処理向け) |
| `user-invocable: false` | Claude のみ起動可能 (背景知識向け) |

### `context: fork` を使う場面
- サブエージェントで隔離実行したいとき
- 読み取り専用の探索タスク
- メインの文脈を汚したくない重い調査タスク

## SKILL.md テンプレート

```yaml
---
name: skill-name
description: What this skill does and when to use it
# Optional fields below:
# disable-model-invocation: true  # Only manual invocation
# user-invocable: false          # Only Claude can invoke
# allowed-tools: Read, Grep      # Restrict tool access
# context: fork                  # Run in subagent
# agent: Explore                 # Agent type for fork
---

# Skill Title

Brief description of what this skill does.

## Task

Clear, step-by-step instructions.

Use `$ARGUMENTS` for user input.
Use `$0`, `$1` for positional args.
```

## ガイドライン

- **SKILL.md は 500 行以内に保つ** - 詳細は補助ファイルへ切り出す
- **description が最重要** - Claude が発動可否をこれで判断する
- **最小限から始める** - 必要になってから複雑さを足す
- **`$ARGUMENTS` を使う** - 動的なユーザー入力のため
- **補助ファイル** - SKILL.md から参照し、必要時に読み込ませる
