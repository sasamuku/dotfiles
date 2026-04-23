---
name: commit
description: Creates logical, well-structured git commits following Conventional Commits. Use when user mentions commit, committing, saving changes, or asks to organize changes into commits.
disable-model-invocation: true
---

# Commit

Conventional Commits 仕様に従い、論理的で構造化された git コミットを作成する。

## オプション

- `-y`: ユーザー承認をスキップして、そのままコミット作成に進む

## 手順

### 1. 現在の変更を確認する

```bash
git branch --show-current
git status
git diff
git diff --cached
git log --oneline -5
```

### 2. 変更を分析する

- 機能・モジュール・変更種別でファイルをグルーピングする
- 各グループの種別 (feat, fix, docs, chore, refactor, style, test, perf, build, ci) を判別する
- 依存関係を踏まえた適切なコミット順序を決定する
- 各コミットがアトミックで自己完結していることを確認する

### 3. コミット計画を提示し、承認を得る

Conventional Commits 形式 (絵文字なし) でコミット計画を提示する:

```
Commit Plan:

1. feat(auth): add user authentication feature
   - apps/api/src/features/auth/login-usecase.ts
   - apps/api/src/features/auth/route.ts

2. test(auth): add authentication test cases
   - apps/api/src/features/auth/login-usecase.spec.ts

3. docs(api): update API documentation
   - docs/api/authentication.md

4. chore(deps): add authentication libraries
   - package.json
   - pnpm-lock.yaml

Do you approve this commit plan? (y/n)
If changes are needed, please specify what adjustments are required.
```

**重要**: コミット作成に進む前に、明示的なユーザー承認を待つこと。

**例外**: `-y` オプションが指定されている場合は承認ステップを飛ばし、直接コミット作成へ進む。

### 4. 各コミット前に型チェック・リント

各コミットを作成する前に、型チェックとリントを実行する:

```bash
npm run type-check || pnpm type-check || tsc --noEmit
npm run lint || pnpm lint
```

エラーが見つかればコミット前に修正する。スクリプトが存在しない場合は省略する。

### 5. 論理単位でコミットを作成する

承認後、各コミットを作成する:

```bash
git add [related-files]
git commit -m "$(cat <<'EOF'
type(scope): concise subject line

- Detailed change description 1
- Detailed change description 2
- Detailed change description 3
EOF
)"
```

### 6. コミット作成の原則

- **1 コミット 1 目的**: 単一責任原則に従う
- **依存を意識**: 依存関係を尊重する順序でコミットする
- **ビルドを壊さない**: 各コミットがビルド可能な状態を保つ
- **アトミックなコミット**: 各コミットが自己完結し、取り消し可能であること
- **明確なメッセージ**: 「何」だけでなく「なぜ」を説明する分かりやすいメッセージにする

## コミットタイプ

- **feat(module)**: 新機能
- **fix(module)**: バグ修正
- **docs(module)**: ドキュメント変更
- **chore(module)**: 雑務 (依存更新、設定変更など)
- **refactor(module)**: 機能変更を伴わないリファクタリング
- **style(module)**: コードスタイル変更 (フォーマット、空白など)
- **test(module)**: テストの追加・更新
- **perf(module)**: パフォーマンス改善
- **build(module)**: ビルドシステム変更
- **ci(module)**: CI/CD 設定変更

## コミットメッセージフォーマット

```
type(scope): subject

body (optional)

footer (optional)
```

- **type**: 必須 (feat, fix, docs, etc.)
- **scope**: 任意だが推奨 (モジュール・コンポーネント名)
- **subject**: 必須。命令形で簡潔に
- **body**: 任意。箇条書きで詳細を記述
- **footer**: 任意。破壊的変更や Issue 参照など

**絵文字禁止**: プレーンテキストのみで書く。

## 注意事項

- **ブランチは作成しない**: このコマンド内で新規ブランチを作らない
- **型チェック/リントのみ**: テストは実行しない (テストはユーザーが別途対応)
- **対話的**: `-y` が指定されない限り、実行前に必ず計画をユーザーに確認する
- **厳密なフォーマット**: Conventional Commits に従い、絵文字は使わない
- **逐次実行**: バッチではなく、1 コミットずつ順に作成する

## 引数

$ARGUMENTS
