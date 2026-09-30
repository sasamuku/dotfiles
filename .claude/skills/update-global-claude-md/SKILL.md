---
name: update-global-claude-md
description: Edit ~/.claude/CLAUDE.md when the user explicitly requests a global Claude instruction change; excludes project-local instructions.
---

# Update Global Claude Instructions

1. `~/.claude/CLAUDE.md` のsymlinkを辿り、実体と所属dotfilesリポジトリを解決する。ユーザー名・絶対パスを固定せず、編集対象をプロジェクトの `CLAUDE.md` と混同しない。
2. dotfiles側のブランチ・未コミット変更を確認し、実体を読む。依頼された箇所だけ既存の書式・トーンで編集する。不明点は確認する。
3. 対象ファイルの差分を提示し、承認後にそのファイルだけコミットする。メッセージは `docs(claude): <変更内容>`。他の変更を巻き込まず、pushは明示指示がある場合だけ行う。
