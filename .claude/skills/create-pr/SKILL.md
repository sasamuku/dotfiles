---
name: create-pr
description: Create a GitHub PR using repository conventions, fix CI failures, then present review-comment triage. Honor requests to leave it draft or only create the PR.
disable-model-invocation: true
---

# Create PR

引数: $ARGUMENTS

## PR 作成

1. PR テンプレート (`.github/pull_request_template.md`、大文字名、同名ディレクトリ) とリポジトリ指示を確認する。テンプレートがなければ直近の PR を参考にし、慣習もなければ Summary / Test Plan の最小構成にする。
2. base、現在のブランチ、全コミット・差分を確認し、ブランチを push する。upstream 未設定なら `git push -u origin <branch>`。
3. タイトル・本文をリポジトリ指定の言語に揃える。指定がなければテンプレート、直近 PR の言語の順で判断する。タイトルは既存慣習を優先し、なければ絵文字なしの Conventional Commits。
4. 本文を一時ファイルに作り、`gh pr create --draft --title "..." --body-file <file> --base <base>` で作成する。編集済みの本文をテンプレートで上書きしない。
5. `gh pr view <N> --json title,body,isDraft,url` で結果を確認する。

## テンプレートの扱い

- 見出し・順序を保ち、独自の節を追加しない。該当しない節は N/A 等で示す。
- bot 制御・自動補完マーカー・明示された保持指示の HTML コメントは変更しない。そのコメントだけの節に埋め草を足さない。
- 自由記述の案内コメントは記入後に削除する。判別がつかなければ保持する。
- PR 本文には最終的な変更と検証を書く。作業経緯は判断に必要な場合だけ含める。

## 作成後

「draft のまま」「PR 作成だけ」の指定があれば、ここは実行しない。

1. `gh pr ready <N>` で Ready にし、`gh pr checks <N> --watch` で CI 完了を待つ。
2. 失敗は [babysit](../babysit/SKILL.md) の CI 取得・分類・修正方針に従って直し、`/commit -y` → `git push` → CI 確認を行う。修正は最大3巡。インフラ等の修正不能な失敗は理由を報告し、成功扱いにしない。
3. CI が green なら `/babysit` の対話モードでレビューコメントと修正案を提示する。修正・返信はその場の承認範囲に従う。レビュー未着ならその旨を伝える。
