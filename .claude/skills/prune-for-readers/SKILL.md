---
name: prune-for-readers
description: Shorten documentation and code comments by removing repetition, obvious explanations, and obsolete process notes while preserving facts and decision-relevant context.
---

# Prune for Readers

対象: $ARGUMENTS。指定がなければ直近の変更で書いた文書・コメント。

読者の理解・判断に寄与しない記述を削り、重複をまとめる。削減のために事実・条件・意味を変えない。

- 削る: 作業実況、文書の自己紹介、自明な処理の説明、その場に固有でない一般論、同じ指示の言い換え。
- 残す: 現在の判断根拠、外部制約、落とし穴、意図的な逸脱、未解消の制限。単に「暫定」「将来」と書かれているだけでは削らない。
- ADR・Design Doc・CHANGELOG・PR本文・コミットメッセージでは、目的に必要な意思決定や変更履歴を保持する。
- 文書構造は読みやすさに必要な範囲で保つ。重複の参照化は、その参照先を読む負担も考慮する。
- 矛盾や削除判断の割れる箇所は勝手に解釈を確定せず、ユーザーに示す。

変更後は意味の保持と参照切れを確認する。圧縮量を求められた場合は変更前後の文字数・削減率を報告し、文字数をトークン数と混同しない。
