---
name: commit-and-pr
description: Commit changes, push, and create a draft GitHub PR.
disable-model-invocation: true
---

`/commit` で変更をコミットし、`/create-pr` で push・PR 作成を行う。draft のまま残し、Ready 化・CI 修正・コメントトリアージは依頼された場合だけ実行する。
