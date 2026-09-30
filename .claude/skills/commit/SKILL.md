---
name: commit
description: Organize requested changes into logical Conventional Commits following the repository's language and conventions.
disable-model-invocation: true
---

# Commit

引数: $ARGUMENTS (`-y`: 確定済みの範囲を追加確認せず実行)

1. ブランチ、作業差分、ステージ済み差分、直近の履歴を確認する。他の作業を巻き込まず、1コミット1目的でまとめる。
2. 対象が明確なコミット依頼・承認済み計画はそのまま実行する。含める変更が曖昧なら、対象とメッセージを提示して確認する。
3. 関連する型チェック・lint が未実施なら、リポジトリの実在するコマンドで実行する。通過済みで差分が増えていなければ繰り返さない。このスキルではテストを新たに起動しない。
4. 対象パスだけを stage し、`git diff --cached --check` と差分を確認してコミットする。
5. コミットと残る作業差分を報告する。

メッセージは `type(scope): subject`。直近履歴の言語に合わせ、混在時は英語を既定とする。絵文字なし。本文は必要時だけ付ける。
ブランチ作成・push・既存コミットの書き換えはこのスキルに含めない。
