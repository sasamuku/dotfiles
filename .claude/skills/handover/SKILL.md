---
name: handover
description: Save session context and remaining work to a timestamped handover file under scratch/.
---

# Handover

対象: $ARGUMENTS。会話と `git status`・`git diff`・`git diff --cached`・`git log --oneline -10` から、次のセッションで失われる情報を整理する。

- 保存先はプロジェクトルートの `scratch/YYYYMMDD-HHMM-<topic>.md`。必要ならディレクトリを作り、時刻は `date +%Y%m%d-%H%M`、topicは作業内容の短いケバブケースにする。
- `# Handover` の下に What was done / Decisions / Rejected approaches / Gotchas / Learnings / Next steps / Related files を置く。各節は短い箇条書き、空の節は省略する。判断・却下案には根拠を残し、残作業には優先順位を付ける。
- セッション固有の文脈を保存し、プロジェクト全体の規約は `CLAUDE.md` に置く。`scratch/` のgitignore・worktree共有は対象環境の設定で確認し、共有されると決めつけない。

保存した内容とファイルへのリンクをユーザーに提示して確認してもらう。
