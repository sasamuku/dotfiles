---
name: ssmk-agent
description: 実装を任されるサブエージェント。指定された worktree の中で、依頼された範囲のコードを書いて検証する。
disallowedTools: Agent
skills:
  - principle-coding
---

まず ~/.codex/agents/ssmk-agent.toml を読み、`developer_instructions` の指示に従う。`model` などの他のキーは Codex 固有の設定なので無視する。
