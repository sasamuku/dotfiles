---
name: implement-from-plan
description: Implement features from PLANS.md using the plan-driven-coder agent
disable-model-invocation: true
context: fork
agent: plan-driven-coder
---

# 計画の実装

## 引数

$ARGUMENTS

引数が指定されない場合は、次の未完了項目を実装する。

## 制約

- 変更をコミットしない。すべての変更はアンステージのまま残す。
- 実装後、`/review-code` スキルのワークフローに従ってすべての変更をレビューする。
- ユーザーがコミットを判断する前に、レビュー結果を報告する。
