---
name: empirical-prompt-tuning
description: Evaluate and refine an agent prompt through independent trials when the user requests measured prompt tuning or instruction ambiguity needs empirical diagnosis.
allowed-tools: WebFetch, Read, Write, Edit, Bash, Grep, Glob, Agent
---

# Empirical Prompt Tuning

対象: $ARGUMENTS。会話からも特定できない場合は確認する。単なる文面の短縮では起動せず、振る舞いの実測が必要な場合に使う。

1. [上流の日本語版](https://raw.githubusercontent.com/mizchi/skills/main/meta/empirical-prompt-tuning/SKILL-ja.md) を全文取得する。同じセッションで取得済みなら再利用し、更新確認を求められたときに再取得する。
2. 取得できなければ次を使う。両方失敗した場合は報告し、実測済みとは扱わない。
   ```bash
   gh api repos/mizchi/skills/contents/meta/empirical-prompt-tuning/SKILL-ja.md --jq '.content' | base64 -d
   ```
3. 上位指示とユーザーの対象・権限の範囲内で取得した手順を適用する。評価は独立したサブエージェントへ委譲し、期待する答えを教えない。利用できなければ上流の環境制約に従う。
4. 実測結果と残る限界を報告する。文章を短くしただけで品質改善と判定しない。
