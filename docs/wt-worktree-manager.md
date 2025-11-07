# Git Worktree Manager (wt)

fzfを使った対話的なインターフェースを備えた、効率的なgit worktree管理用のカスタムZsh関数です。

## 概要

`wt`は対話的なインターフェースと一般的なワークフローの自動化により、git worktree操作を簡素化します。Worktreeは`.git/tmp_worktrees/`配下のタイムスタンプ付きディレクトリに作成されるため、識別と管理が容易です。

## コマンド

### `wt` - 対話的なWorktreeブラウザ

fzfの対話的なインターフェースですべてのworktreeを表示します。Enterキーで選択したworktreeに移動できます。

```bash
wt
```

**機能:**
- ブランチ名とパスの表示
- 変更ファイルのステータス（変更、追加、削除、未追跡）
- 最近のコミットのプレビュー（直近10件）
- 絵文字による視覚的なインジケーター

### `wt add <branch>` - 新しいWorktreeを作成

新しいブランチとworktreeを一つのコマンドで作成します。

```bash
wt add feature/new-feature
```

**動作:**
- 指定された名前で新しいブランチを作成
- `.git/tmp_worktrees/<timestamp>_<branch>/`にworktreeを作成
- 自動的に新しいworktreeに移動
- `.wt_hook.sh`が存在する場合は実行（下記のHookシステムを参照）

**例:**
```bash
$ wt add feature/auth
Created worktree at: /path/to/repo/.git/tmp_worktrees/20250103_143022_feature/auth
Branch: feature/auth
```

### `wt remove <branch>` - Worktreeを削除

worktreeを削除し、ブランチも削除します。

```bash
wt remove feature/new-feature
```

**動作:**
- ブランチ名でworktreeを検索
- worktreeディレクトリを強制削除
- ブランチを削除（`git branch -D`）

### `wt pr <PR-URL>` - GitHub PRからWorktreeを作成

GitHub PRのブランチからworktreeを作成します。

```bash
wt pr https://github.com/owner/repo/pull/123
# または
wt pr 123
```

**動作:**
- PR URLまたは番号からPR情報を取得（`gh` CLI使用）
- PRブランチを`pr-<番号>`としてチェックアウト
- `<project>-pr-<番号>/`にworktreeを作成
- `.wt_hook.sh`が存在する場合は実行
- 自動的に新しいworktreeに移動

**例:**
```bash
$ wt pr https://github.com/user/repo/pull/42
Fetching PR #42 information...
PR branch: feature/new-ui
Creating worktree for PR #42: pr-42
Created worktree at: /path/to/repo-pr-42
Branch: pr-42

✅ Worktree ready for PR #42
```

### `wt init` - Hookテンプレートを作成

現在のディレクトリに`.wt_hook.sh`テンプレートファイルを生成します。

```bash
wt init
```

プロジェクトルートから新しいworktreeに`.env`と`.claude`をコピーするテンプレートを作成します。プロジェクトのニーズに合わせてカスタマイズできます。

## Hookシステム

`.wt_hook.sh`ファイルは、`wt add`が新しいworktreeを作成した後に自動的に実行されます。これにより、各worktreeのセットアップタスクを自動化できます。

### 利用可能な変数

- `$WT_WORKTREE_PATH` - 新しいworktreeのパス（カレントディレクトリ）
- `$WT_BRANCH_NAME` - ブランチ名
- `$WT_PROJECT_ROOT` - 元のプロジェクトルートのパス

### Hookの例

```bash
#!/bin/bash
# .wt_hook.sh

# 設定ファイルをコピー
copy_items=(".env" ".claude" ".vscode")

for item in "${copy_items[@]}"; do
    if [[ -f "$WT_PROJECT_ROOT/$item" ]]; then
        cp "$WT_PROJECT_ROOT/$item" "$item"
        echo "Copied file $item to worktree"
    elif [[ -d "$WT_PROJECT_ROOT/$item" ]]; then
        cp -r "$WT_PROJECT_ROOT/$item" "$item"
        echo "Copied directory $item to worktree"
    fi
done

# 依存関係をインストール
npm install

# バックグラウンドで開発サーバーを起動
npm run dev &
```

## ユースケース

### 複数の機能を同時に開発

```bash
# 異なる機能用のworktreeを作成
wt add feature/user-auth
wt add feature/api-refactor
wt add bugfix/payment-error

# 対話的なブラウザで切り替え
wt
```

### プルリクエストのレビュー

```bash
# PR用のworktreeを作成（自動でPRブランチをチェックアウト）
wt pr https://github.com/owner/repo/pull/123

# PRの内容を確認
gh pr view 123

# レビュー完了後、クリーンアップ
wt remove pr-123
```

### 開発とテストの分離

```bash
# メインの開発を一つのworktreeで維持
wt add feature/new-ui

# テスト用に別のworktreeを作成
wt add test/integration-tests
```

## Tips

1. **タイムスタンプディレクトリ**: Worktreeはタイムスタンプ付きで作成されるため（例: `20250103_143022_feature/auth`）、作成時期を簡単に識別できます。

2. **クリーンな作業ツリー**: 対話的なブラウザはファイル変更を表示するため、コミットされていない変更があるworktreeを識別できます。

3. **Hook自動化**: `.wt_hook.sh`を使用して、次のような反復的なセットアップタスクを自動化できます:
   - 環境ファイルのコピー
   - 依存関係のインストール
   - 開発サーバーのセットアップ
   - 必要なディレクトリの作成

4. **プロジェクトの分離**: 各worktreeは独自の作業ディレクトリを持つため、次のことが可能です:
   - 異なる開発サーバーを同時に実行
   - stashせずに異なるブランチをテスト
   - 現在の作業を中断せずにPRをレビュー

5. **PRワークフロー**: `wt pr`コマンドを使用することで:
   - 現在のブランチの環境を汚さずにPR専用環境を構築
   - フォークからのPRも同一リポジトリのPRも同じコマンドで処理
   - ワンコマンドでPRブランチからworktreeを作成
   - レビュー完了後は`wt remove`で簡単にクリーンアップ

## 必要要件

- Git 2.5+ (worktreeサポート)
- fzf (ファジーファインダー)
- Zsh shell
- gh CLI (GitHubコマンドラインツール、`wt pr`コマンドに必要)

## 配置場所

関数定義: `.config/zsh/functions/wt.zsh`

## 関連するGitエイリアス

`.gitconfig`の関連するgit worktreeエイリアスを参照:
- `wa` - `git worktree add`
- `wl` - `git worktree list`
- `wr` - `git worktree remove`
