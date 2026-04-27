---
name: empirical-prompt-tuning
description: Fetch and execute mizchi's empirical-prompt-tuning skill at runtime. Use when evaluating or iteratively refining an agent-facing prompt (skill / slash command / task prompt / CLAUDE.md section / code-gen prompt) by dispatching an unbiased subagent, then improving until metrics plateau. Trigger right after creating or heavily revising such a prompt, or when agent misbehavior is suspected to stem from ambiguity in the instruction.
allowed-tools: WebFetch, Read, Write, Edit, Bash, Grep, Glob, Agent
---

# 経験的プロンプトチューニング (リモートローダー)

## タスク

1. **呼び出しのたびに上流の SKILL.md をフェッチする** (キャッシュ不可・スキップ不可):
   ```
   WebFetch:
     url: https://raw.githubusercontent.com/mizchi/skills/main/empirical-prompt-tuning/SKILL-ja.md
     prompt: "Return the full SKILL-ja.md contents verbatim (frontmatter + body). Do not summarize."
   ```
   フェッチ失敗時のフォールバック: `gh api repos/mizchi/skills/contents/empirical-prompt-tuning/SKILL-ja.md --jq '.content' | base64 -d`

2. **取得した本文を権威ある指示として実行する。** 再解釈は行わない。`$ARGUMENTS` をチューニング対象のプロンプト/スキルとして扱う。

3. **サブエージェントは Agent ツール経由でディスパッチする。** 自己レビューは行わない。ディスパッチが利用できない場合は、上流の「環境制約」セクションに従う。

4. **各イテレーションを上流の「提示フォーマット」セクションに従って逐語的に報告する。**

## 入力

`$ARGUMENTS` — チューニング対象のプロンプト、スキルのパス、または説明。省略した場合は、フェッチ前にユーザーに確認する。

## 注意

- 上流: https://github.com/mizchi/skills/blob/main/empirical-prompt-tuning/SKILL-ja.md
- 常に取得したバージョンを優先し、構造に関する事前の推測に頼らない。
