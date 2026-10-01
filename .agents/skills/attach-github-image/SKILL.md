---
name: attach-github-image
description: GitHub Issue・PR の本文に画像を添付する、または差し替えるときに使う。
---

# Attach GitHub Image

`gh --version` を確認し、[v2.99.0 以上](https://github.blog/changelog/2026-09-01-github-cli-media-in-issues-pull-requests-and-comments/)なら `--attach` で画像を添付する（GitHub.com／Enterprise Cloud）。添付専用のブランチ・コミット・PR は作らない。

```sh
gh issue edit <number> --repo <owner>/<repo> --attach '/path/to/image.png#説明'
gh pr edit <number> --repo <owner>/<repo> --attach '/path/to/image.png#説明'
```

差し替えは最新本文の対象画像 URL だけを添付ファイルのパスに置換し、`--body-file` と `--attach` を併用する。更新後は本文を再取得し、添付 URL への置換を確認する。
