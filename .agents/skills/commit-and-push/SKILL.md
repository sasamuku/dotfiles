---
name: commit-and-push
description: Commit changes and push the current branch.
disable-model-invocation: true
---

`/commit` で変更をコミットし、`git push` する。upstream 未設定なら送信先を確認して `git push -u <remote> <branch>`。別ブランチや force push に切り替えない。
