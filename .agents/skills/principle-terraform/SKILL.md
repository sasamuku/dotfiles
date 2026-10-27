---
name: principle-terraform
description: Terraform の構成を設計、レビュー、変更するときの原則と事例。module と state の境界、backend の初回構築、環境の取り違えの防ぎ方、設計判断の根拠の示し方を扱う。
disable-model-invocation: true
---

# Terraform

Terraform の原則を論点ごとに分けて置く。該当する論点の資料だけを読む。

| 原則 | 要点 | 読むとき |
|---|---|---|
| [module の設計](references/module-design.md) | root は組み立てに専念し、機能は child module に置く。環境、root と state、child module の境界を別々に考える | 構成の設計とレビュー |
| [state](references/state.md) | state は実環境の正本であり、秘密情報でもある。1 か所の共有された保存先に置いて守り、手元に残さない | state の分割、backend の初回構築、既存資産を保つ変更 |
| [環境の取り違え](references/environment-safety.md) | 誤った環境への適用は、人の注意ではなく設定で防ぐ | provider と backend の設定、CI の権限、変更の確かめ方 |
| [根拠の示し方](references/evidence.md) | 参照資料のプラクティスと、対象コードからの設計判断を書き分ける | 設計判断を説明するとき |
