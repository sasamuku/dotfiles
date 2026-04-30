---
name: update-global-claude-md
description: Updates the user's global Claude Code instructions file (~/.claude/CLAUDE.md, which is a symlink into the dotfiles repo). Use ONLY when the user explicitly asks to update, edit, add to, or remove from the global CLAUDE.md / global rules / global Claude instructions — typically while working in a different project where ~/.claude/CLAUDE.md isn't the primary editing target. Do NOT trigger for project-local CLAUDE.md files.
disable-model-invocation: true
---

# update-global-claude-md

別プロジェクトで作業中に、グローバル CLAUDE.md (`~/.claude/CLAUDE.md` — dotfiles リポジトリへのシンボリックリンク) を更新する。

## 手順

### 1. 実体パスと dotfiles リポジトリを解決する

シンボリックリンク経由ではなく必ず**実体パス**を編集対象にする (リンクへの書き込みは環境次第で予期せぬ挙動になるため)。ホームディレクトリやユーザー名はマシンごとに異なるので絶対パスをハードコードしない。

```bash
TARGET=$(readlink ~/.claude/CLAUDE.md)
DOTFILES_DIR=$(git -C "$(dirname "$TARGET")" rev-parse --show-toplevel)
```

### 2. 編集する

ユーザーがプロンプトに書いた更新内容を読み取り、曖昧なら短く確認する。Read で `$TARGET` を開き、Edit で該当箇所を更新する。書式・トーン・見出しレベルは既存に合わせる。

### 3. 差分を見せて、承認後にコミットする

```bash
git -C "$DOTFILES_DIR" diff -- .claude/CLAUDE.md
```

承認されたらコミットする。push は明示指示があるときだけ。

```bash
git -C "$DOTFILES_DIR" add .claude/CLAUDE.md
git -C "$DOTFILES_DIR" commit -m "docs(claude): <変更内容の要約>"
```

## 注意事項

- **dotfiles の作業状態を尊重する**: 編集前に `git -C "$DOTFILES_DIR" status` でブランチと未コミット変更を確認し、意図しない他の変更を巻き込まない。
- **プロジェクト CLAUDE.md と混同しない**: 作業中ディレクトリの `./CLAUDE.md` や `./.claude/CLAUDE.md` はプロジェクト固有の指示。このスキルはグローバル設定専用。