# コーディングスタイル

> [everything-claude-code](https://github.com/affaan-m/everything-claude-code) より翻案 (MIT License)

## イミュータビリティ (CRITICAL)

常に新しいオブジェクトを生成し、**決してミューテーションしない**:

```javascript
// WRONG: Mutation
function updateUser(user, name) {
  user.name = name  // MUTATION!
  return user
}

// CORRECT: Immutability
function updateUser(user, name) {
  return {
    ...user,
    name
  }
}
```

## ファイル編成

**小さなファイルを多数** > **大きなファイルを少数**:
- 高凝集・低結合
- 通常は 200〜400 行、最大 800 行
- 大きなコンポーネントからユーティリティを抽出する
- 型ではなく、機能・ドメインで整理する

## エラーハンドリング

エラーは常に漏れなく処理する:

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('Detailed user-friendly message')
}
```

## 入力バリデーション

常にユーザー入力をバリデーションする:

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## コード品質チェックリスト

作業を完了とマークする前に:
- [ ] 読みやすく、適切に命名されているか
- [ ] 関数は小さい (50 行未満) か
- [ ] ファイルは焦点が絞られている (800 行未満) か
- [ ] 深いネスト (4 レベル超) がないか
- [ ] 適切なエラーハンドリングがあるか
- [ ] `console.log` 文が残っていないか
- [ ] ハードコードされた値がないか
- [ ] ミューテーションがない (イミュータブルパターンを使用) か
