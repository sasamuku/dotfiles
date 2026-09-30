# Pending Review の投稿

ユーザーが選んだ指摘だけを投稿し、submit せず Pending 状態に残す。行番号未確定・PR全体の指摘はインライン投稿しない。

- `path` はファイル、`line` は元ファイルの絶対行番号、`side` は head 側 RIGHT / base 側 LEFT。範囲指定なら `start_line` と対応する `start_side` も含める。
- `body` は統合済み指摘のタイトルと本文。構造化メタデータは入れず、優先度ラベルは絵文字と重複させない。
- 指摘範囲の完全な置換なら `suggestion` ブロックを使い、それ以外は通常のコードブロックにする。
- API 失敗時はエラーと未投稿分を報告し、成功した投稿を重複作成しない。

**1. 既存 Pending Review を確認** (自分が作成したもののみ対象):

```bash
ME=$(gh api user --jq .login)
gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews \
  --jq ".[] | select(.state == \"PENDING\") | select(.user.login == \"$ME\") | {id, state, user: .user.login}"
```

**2a. Pending Review なし → REST API で新規作成**

`event` フィールドを**省略**すると pending 状態になる (`event: "PENDING"` を明示すると `422`):

```bash
cat <<'PAYLOAD' | gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews --method POST --input -
{
  "comments": [
    {
      "path": "src/example.ts",
      "line": 10,
      "side": "RIGHT",
      "body": "🔴 **Critical**: SQL injection via unsanitized input\n\nUse parameterized queries."
    }
  ]
}
PAYLOAD
```

**2b. Pending Review あり → GraphQL でコメント追加** (REST では既存 pending にコメント追加不可)

Node ID 取得 → コメント追加:

```bash
gh api graphql -f query="
{
  repository(owner: \"{owner}\", name: \"{repo}\") {
    pullRequest(number: {PR番号}) {
      reviews(states: PENDING, first: 20) {
        nodes { id state author { login } }
      }
    }
  }
}" --jq ".data.repository.pullRequest.reviews.nodes[] | select(.author.login == \"$ME\")"
```

```bash
cat <<'GQL' | gh api graphql --input -
{
  "query": "mutation($input: AddPullRequestReviewThreadInput!) { addPullRequestReviewThread(input: $input) { thread { id comments(first: 1) { nodes { id body } } } } }",
  "variables": {
    "input": {
      "pullRequestReviewId": "PRR_kwDOxxxxxxx",
      "path": "src/example.ts",
      "line": 10,
      "side": "RIGHT",
      "body": "コメント本文"
    }
  }
}
GQL
```
