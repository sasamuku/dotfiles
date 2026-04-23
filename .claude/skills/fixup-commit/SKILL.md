---
name: fixup-commit
description: Creates a fixup commit and performs autosquash rebase
disable-model-invocation: true
---

# Fixup Commit

指定した対象コミットに対して fixup コミットを作成し、autosquash 付きの対話的リベースを実行する。

## 引数

fixup 対象のコミットハッシュ。

$ARGUMENTS

## 手順

### 1. 引数の検証

引数が提供されていない場合、対象コミットハッシュをユーザーに確認する。

### 2. 現在の変更を確認する

```bash
git status
git diff
git diff --cached
git log --oneline -10
```

### 3. 対象コミットの情報を取得する

```bash
git log --format="%H %s" -1 <target-commit>
```

### 4. 確認を求める

次の情報を表示し、ユーザーの承認を得る:

```
Fixup Commit Plan:

Target commit: <commit-hash>
Commit message: <commit-message>

Files to be included in fixup:
- <file1>
- <file2>
- ...

This will:
1. Stage all changes (if not already staged)
2. Create a fixup commit for the target
3. Run interactive rebase with autosquash

Proceed? (y/n)
```

**重要**: 明示的な承認 (y) を待ってから進めること。

### 5. Fixup を実行する

ユーザー承認後:

```bash
git add -A
git commit --fixup=<target-commit>

# Show rebase plan (for verification)
GIT_SEQUENCE_EDITOR="cat" git rebase -i --autosquash main --no-edit 2>/dev/null || true

# Execute rebase with autosquash
git rebase -i --autosquash main
```

### 6. 結果を確認する

```bash
git log --oneline -10
```

## 注意事項

- **作業ツリーがクリーン、または変更がステージ済みであること**: 未ステージの変更は自動でステージされる
- **対象コミットが存在すること**: コミットハッシュが無効なら失敗する
- **main に対してリベースする**: リベース対象は main ブランチ
- **対話的確認**: 実行前に必ずユーザーへ確認する
