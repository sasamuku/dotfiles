---
name: handover
description: Generate a HANDOVER.md file summarizing the current session's work. Use at the end of a session to preserve context for the next session.
disable-model-invocation: true
---

# Handover

現在のセッションの文脈を次のセッションへ引き継ぐためのハンドオーバーファイルを作成する。

## 手順

### 1. コンテキストを収集する

現在のセッションの会話を振り返り、以下を整理する:

- 取り組んだ内容
- 下した判断とその根拠
- 試したが採用しなかったアプローチ
- 直面した問題とその解決方法
- 得られた学び
- 残っている作業

### 2. 変更内容を確認する

```bash
git status
git diff
git diff --cached
git log --oneline -10
```

### 3. 保存先を決定する

プロジェクトルートに `scratch/` ディレクトリがあるか確認する:

- **`scratch/` が存在する場合**: `scratch/<descriptive-name>.md` (例: `scratch/auth-refactor-handover.md`) として保存する。セッションの作業内容を反映した名前を選ぶ。
- **`scratch/` が存在しない場合**: プロジェクトルートに `HANDOVER.md` として保存する。

### 4. ハンドオーバーファイルを生成する

以下のセクション構成で書き出す:

```markdown
# Handover

## What was done
- [Completed work items with brief descriptions]

## Decisions
- [Design decisions and their rationale]

## Rejected approaches
- [Approaches considered but not adopted, with reasons]

## Gotchas
- [Problems encountered and their solutions]

## Learnings
- [Key insights gained during the session]

## Next steps
- [Remaining work items, in priority order]

## Related files
- [Files that were created or modified]
```

### 5. 確認する

生成した内容をユーザーに見せて確認してもらう。

## 注意事項

- 各セクションは簡潔にまとめ、箇条書きのみで書く
- 空のセクションは省略する
- コンテキストがリセットされた際に失われる情報にフォーカスする
- ハンドオーバーファイルはセッション固有のコンテキスト用。プロジェクト全体のルールは `CLAUDE.md` に置く
- `scratch/` は gitignore されるが worktree 間で共有されるため、ハンドオーバーファイルの置き場所として最適

$ARGUMENTS
