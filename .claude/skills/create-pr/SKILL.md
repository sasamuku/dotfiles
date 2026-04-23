---
name: create-pr
description: Create a GitHub pull request using gh CLI with proper formatting
disable-model-invocation: true
---

# Create PR

GitHub CLI を使ってプルリクエストを作成する。

## 新規プルリクエストの作成

1. まず `.github/pull_request_template.md` のテンプレートに沿って PR 説明を用意する

2. `gh pr create --draft` コマンドを使う:

```bash
gh pr create --draft --title "feat(scope): your descriptive title" --body "Your PR description" --base main
```

フォーマットを整えた複雑な説明文を使う場合は `--body-file` を利用する:

```bash
gh pr create --draft --title "feat(scope): your descriptive title" --body-file .github/pull_request_template.md --base main
```

## ベストプラクティス

1. **言語**: PR のタイトル・説明は常に英語で書く

2. **PR タイトル形式**: Conventional Commits 形式を使う (絵文字なし)
   - コミットメッセージと同じ形式: `type(scope): description`
   - 例:
     - `feat(supabase): add staging remote configuration`
     - `fix(auth): fix login redirect issue`
     - `docs(readme): update installation instructions`

3. **説明テンプレート**: `.github/pull_request_template.md` の PR テンプレート構成を必ず使う

4. **テンプレート準拠**: PR 説明はテンプレートの構成に忠実に従うこと:
   - PR-Agent セクション (`pr_agent:summary`, `pr_agent:walkthrough`) は変更・改名しない
   - セクション見出しはテンプレートと完全一致させる
   - テンプレートにないカスタムセクションは追加しない

5. **ドラフト PR**: 作業途中はドラフトで開始する
   - コマンドに `--draft` フラグを付ける
   - 完成したら `gh pr ready` でレビュー準備完了に切り替える

### ありがちなミス

- **英語以外のテキスト**: PR の内容はすべて英語で書く
- **誤ったセクション見出し**: テンプレートと完全に同じ見出しを使う
- **カスタムセクションの追加**: テンプレートに定義されたセクションに留める
- **古いテンプレートの利用**: 常に最新の `.github/pull_request_template.md` を参照する
- **セクションの欠落**: "N/A" や "None" であっても、テンプレートのセクションはすべて含める

## よく使う gh CLI コマンド

```bash
gh pr list --author "@me"                        # List your open PRs
gh pr status                                      # Check PR status
gh pr view <PR-NUMBER>                           # View a specific PR
gh pr checkout <PR-NUMBER>                       # Check out a PR branch locally
gh pr ready <PR-NUMBER>                          # Convert draft PR to ready
gh pr edit <PR-NUMBER> --add-reviewer user1,user2 # Add reviewers
gh pr merge <PR-NUMBER> --squash                 # Merge PR
```
