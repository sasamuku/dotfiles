# Projects / Issue Type / カスタムフィールド

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
