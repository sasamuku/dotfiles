---
name: pbcopy
description: macOS でテキストをクリップボードへコピーするときに使う。
---

- pbcopy／pbpaste の両方に `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8` を指定する。
- Python は原文を UTF-8 bytes にして stdin へ渡す。
- pbpaste で読み戻し、末尾改行を含め原文の UTF-8 bytes と完全一致を確認する。比較にシェルのコマンド置換は使わない（末尾改行が消える）。
- コマンド失敗・不一致はエラーとして報告し、一致確認後だけ「コピー完了」と報告する。
