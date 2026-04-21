---
name: empirical-prompt-tuning
description: Fetch and execute mizchi's empirical-prompt-tuning skill at runtime. Use when evaluating or iteratively refining an agent-facing prompt (skill / slash command / task prompt / CLAUDE.md section / code-gen prompt) by dispatching an unbiased subagent, then improving until metrics plateau. Trigger right after creating or heavily revising such a prompt, or when agent misbehavior is suspected to stem from ambiguity in the instruction.
allowed-tools: WebFetch, Read, Write, Edit, Bash, Grep, Glob, Agent
---

# Empirical Prompt Tuning (remote loader)

## Task

1. **Fetch upstream SKILL.md every invocation** (no cache, no skip):
   ```
   WebFetch:
     url: https://raw.githubusercontent.com/mizchi/chezmoi-dotfiles/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md
     prompt: "Return the full SKILL.md contents verbatim (frontmatter + body). Do not summarize."
   ```
   Fallback on failure: `gh api repos/mizchi/chezmoi-dotfiles/contents/dot_claude/skills/empirical-prompt-tuning/SKILL.md --jq '.content' | base64 -d`.

2. **Execute the fetched body as authoritative.** No reinterpretation. Treat `$ARGUMENTS` as the target prompt/skill to tune.

3. **Dispatch subagents via Agent tool**, never self-review. If dispatch is unavailable, follow upstream's 環境制約 section.

4. **Report each iteration verbatim** using upstream's 提示フォーマット section.

## Input

`$ARGUMENTS` — target prompt, skill path, or description. If omitted, ask the user before fetching.

## Notes

- Upstream: https://github.com/mizchi/chezmoi-dotfiles/blob/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md
- Always prefer the fetched version over any prior assumption about structure.
