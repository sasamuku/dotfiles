---
name: create-sub-issue
description: Create a sub-issue linked to a parent GitHub issue, honoring repository-specific issue conventions
disable-model-invocation: true
---

# サブ Issue の作成

サブ Issue API を使って、親 GitHub Issue に紐づくサブ Issue を作成する。本 skill は **リポジトリ固有の Issue 運用** (タイトル規約 / ラベル / GitHub Projects / Issue Type / Team 等のカスタムフィールド) を尊重する前提で動作する。固定のラベル名やテンプレートを鵜呑みにしない。

## 引数

- 親 Issue 番号 (例: `123` または `#123`) または URL
- サブ Issue の説明 (任意)

$ARGUMENTS

## 手順

### 1. 親 Issue のコンテキストを取得する

```bash
gh issue view <issue-number> --json number,title,body,url,labels,projectItems
```

- 親 Issue 本文・既存ラベル・Projects 紐付きを確認する
- 親 Issue に `PLANS_SYNC_MARKER` コメント等、文脈を補足するコメントがあれば参照する (無ければスキップ)

### 2. リポジトリ固有の Issue 運用ルールを確認する

**skill 内に書かれた例 (ラベル名・テンプレ等) を既定値として鵜呑みにしないこと。** 親 Issue が存在するリポの実運用を短く確認し、サブ Issue の規約を合わせる。

a. **タイトル規約**: 親 Issue や既存サブ Issue のタイトルを 2〜3 本サンプル確認する。
   - `feat:` / `fix:` 等の Conventional Commits 接頭辞を付けるか付けないかが分かれる
   - 末尾のカッコ書き補足 (例: 「... (MFA対応)」) を付ける慣習かどうかも確認する
   - 既定は **接頭辞なし・カッコ書き補足なしのシンプルなタイトル**。ユーザーの依頼文にカッコ書きが含まれていても、情報として不可欠でなければタイトルから外し本文側に移す (両案併記でユーザー判断を仰ぐのは最後の手段)

b. **ラベル**: `gh label list --repo <owner>/<repo> --limit 100` でラベル一覧を取得し、存在するラベルのみを使う。
   - 親 Issue や既存サブ Issue が使っているラベルを踏襲するのが無難
   - **存在しないラベル名 (例: `sub-issue`) をそのまま `--label` に渡すと `gh issue create` が失敗する**。skill 内の例示ラベル名は参考に過ぎない
   - 該当するラベルが不明なら `--label` を省略してユーザーに確認する

c. **GitHub Projects / カスタムフィールド**: 親 Issue が Project に紐付いているか、Issue Type / Team 等のフィールドを持つか確認する。
   - 親 Issue を GraphQL で見て `projectItems` / `issueType` / Project のカスタムフィールドを把握する
   - 親 Issue と同じ Project に追加し、同じ Issue Type・Team を設定するのが既定
   - フィールド ID / オプション ID が不明なら GraphQL で事前照会する (本ファイル末尾「リポ固有フィールド設定のリファレンス」参照)

d. **本文テンプレート**: リポに `.github/ISSUE_TEMPLATE/` があれば最適なものを利用する。無ければ親 Issue の本文構造 (Overview / Background / Acceptance criteria 等) を踏襲する。

### 3. サブ Issue のタイトル・本文をドラフトする

- **必須**: 本文の冒頭に `Part of #{parent-issue-number}` を記載する
- タイトルは手順 2a の規約に従う
- 本文内のリンクは **repo ルート相対 (`docs/foo.md`) または フル GitHub URL** で書く。`../../docs/foo.md` のような作業ディレクトリ相対は GitHub Issue 上で切れるので使わない
- `.github/ISSUE_TEMPLATE/` を利用する場合、テンプレ中の HTML コメント (`<!-- ... -->`) は必要な記入箇所に置き換えるか削除する。残すと Issue 本文に白紙の注釈が出る
- フォーカスされた、単独で実行可能な粒度にする
- **ユーザー承認を得てから次の手順に進む** (タイトル・本文ドラフトを提示し承認を待つ)

### 4. Issue を作成する

```bash
ISSUE_URL=$(gh issue create \
  --repo <owner>/<repo> \
  --title "$TITLE" \
  --body "$BODY" \
  <--label オプションは手順 2b で確認したラベルに差し替える。不要なら省略>)
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
```

### 5. 親 Issue に紐づける (Sub Issue API)

```bash
# IMPORTANT: .id (integer) を使う。.node_id (string) ではない
SUB_ISSUE_ID=$(gh api /repos/<owner>/<repo>/issues/$ISSUE_NUMBER --jq .id)
gh api --method POST /repos/<owner>/<repo>/issues/<parent-number>/sub_issues \
  -F "sub_issue_id=$SUB_ISSUE_ID"
```

### 6. リポ固有フィールドを設定する (手順 2c で必要だった場合)

親 Issue と同じ Project / Issue Type / Team を設定する。手順例は本ファイル末尾「リポ固有フィールド設定のリファレンス」を参照。

- **Status フィールド**: 新規 Issue のワークフロー上の初期値 (`New` / `Backlog` など) は通常 Project 側の既定で自動設定される。親と同じ `In Progress` 等に上書きするのはユーザーから明示要求があるときだけ。既定では触らない
- **Priority フィールド**: 同じく未指定で作成し、後から担当者が入れる運用が多い。明示要求が無ければ触らない

### 7. 複数のサブ Issue を作成する場合の順序付け

複数起票で親からの表示順を制御したい場合のみ実行する。単発起票では不要。

```bash
gh api --method PATCH /repos/<owner>/<repo>/issues/<parent-number>/sub_issues/priority \
  --input - <<< '{"sub_issue_id": '$SUB_ISSUE_ID', "after_id": '$PREV_SUB_ISSUE_ID'}'
```

- 新規に N 件を並べる: 先頭の Issue は既存末尾 Issue の後に置き、2 件目以降は直前の新規 Issue の後に置く → PATCH は N 回
- 既存の並び順を崩さず末尾に追加したい: Sub Issue API の POST 時点で末尾に入るため、追加先の順序を弄らないなら PATCH 不要
- 複数起票時は各 Issue で手順 4→5→6 を回し、最後にまとめて本手順で順序付けする

## リポ固有フィールド設定のリファレンス

GitHub Projects のフィールド ID・オプション ID は repo / org ごとに異なる。以下は照会クエリの雛形。

### Projects / Issue Type を親 Issue から調べる

```bash
gh api graphql -f query='
{
  repository(owner: "<owner>", name: "<repo>") {
    issueTypes(first: 20) { nodes { id name } }
    issue(number: <parent-number>) {
      issueType { id name }
      projectItems(first: 5) {
        nodes {
          project { id title number }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field { ... on ProjectV2SingleSelectField { id name } }
                name optionId
              }
            }
          }
        }
      }
    }
  }
}'
```

### Issue Type をサブ Issue に設定

```bash
gh api graphql -f query='
mutation($issueId: ID!, $typeId: ID!) {
  updateIssueIssueType(input: {issueId: $issueId, issueTypeId: $typeId}) {
    issue { number }
  }
}' -f issueId="<issue node_id>" -f typeId="<issue type id>"
```

### Project に追加してカスタムフィールドを設定

```bash
ITEM_ID=$(gh api graphql -f query='
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
    item { id }
  }
}' -f projectId="<project id>" -f contentId="<issue node_id>" --jq '.data.addProjectV2ItemById.item.id')

gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId, itemId: $itemId, fieldId: $fieldId,
    value: { singleSelectOptionId: $optionId }
  }) {
    projectV2Item { id }
  }
}' -f projectId="<project id>" -f itemId="$ITEM_ID" \
   -f fieldId="<field id>" -f optionId="<option id>"
```

## 本文フォーマット

```markdown
Part of #{parent-issue-number}

[リポの慣習に従った本文。親 Issue や `.github/ISSUE_TEMPLATE/` があればそれに合わせる]
```

## ベストプラクティス

- 親 Issue の本文とコメント (`PLANS_SYNC_MARKER` 等、存在すれば) を文脈として活用する
- サブ Issue はフォーカスされた、単独で完結できる内容にする
- **ラベル・タイトル規約・Project / Issue Type / Team はリポごとに違う**。skill の例示を既定値として鵜呑みにせず、手順 2 で毎回確認する
