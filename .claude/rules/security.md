# セキュリティガイドライン

> [everything-claude-code](https://github.com/affaan-m/everything-claude-code) より翻案 (MIT License)

## 必須セキュリティチェック

あらゆるコミットの前に:
- [ ] シークレット (API キー、パスワード、トークン) がハードコードされていない
- [ ] ユーザー入力がすべてバリデーションされている
- [ ] SQL インジェクション対策 (パラメータ化クエリ) が施されている
- [ ] XSS 対策 (HTML サニタイズ) が施されている
- [ ] CSRF 対策が有効になっている
- [ ] 認証・認可が検証されている
- [ ] すべてのエンドポイントにレート制限がある
- [ ] エラーメッセージから機微情報が漏れない

## シークレット管理

```typescript
// NEVER: Hardcoded secrets
const apiKey = "sk-proj-xxxxx"

// ALWAYS: Environment variables
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY not configured')
}
```

## セキュリティ対応プロトコル

セキュリティ上の問題を発見した場合:
1. **直ちに停止する**
2. **security-reviewer** エージェントを使う
3. CRITICAL な問題は続行前に修正する
4. 漏洩した可能性のあるシークレットをローテーションする
5. コードベース全体を見渡し、類似の問題がないか確認する
