# CLAUDE.md

このファイルは Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイドです。`AGENTS.md` はこのファイルへの symlink であり、Codex など他のエージェントも同じ内容を読む (Claude Code 固有の記述は該当製品以外では無視してよい)。

## 概要

macOS のセットアップと設定管理用の個人 dotfiles リポジトリ。Homebrew パッケージ管理、シェルスクリプトによる自動セットアップ、各種開発ツールの設定を含む。

個人リポジトリのため `main` への直接 push・直接変更を許可。PR レビューやフィーチャーブランチは不要。

**ブランチ運用方針はこのプロジェクト CLAUDE.md を優先する** — グローバル指示 (`~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md`) の「main での作業禁止」ルールより、本プロジェクトの方針 (main での直接作業 OK) を採用する。

## セットアップ

新規マシン:
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/sasamuku/dotfiles/master/setup.sh)"
```

スクリプト構成 (いずれも単独実行可):
```
setup.sh
├── setup_brew.sh      # Homebrew + パッケージ
├── setup_zsh.sh       # Zsh + sheldon
├── setup_dotfiles.sh  # Git, Claude, Codex, Neovim
│   ├── setup_claude_mcp.sh  # MCP サーバー
│   └── setup_codex.sh       # Codex (グローバル指示・rules・agent role・共有 skill の symlink)
└── setup_macos.sh     # macOS 環境設定
```

## 構成ファイル

- `Brewfile` — Homebrew パッケージ / cask / VS Code 拡張
- `.zshrc`, `.zprofile`, `.zshenv` — Zsh 設定
- `.config/sheldon/plugins.toml` — sheldon プラグイン
- `.config/starship.toml` — Starship プロンプト
- `.config/mise/config.toml` — mise (Node.js 25.2.1, Go 1.23.2, Ruby 3.2.2)
- `.gitconfig` — Git エイリアス。個人設定は `.gitconfig.local.sample` → `~/.gitconfig.local`
- `.zsh_secrets.example` → `~/.zsh_secrets` (秘密環境変数)
- `.config/nvim/`, `.config/wezterm/`, `.config/ghostty/`, `.config/cmux/`, `.config/lazygit/` — Neovim (Lua), WezTerm, Ghostty, cmux (JSONC), lazygit (delta pager)
- `.claude/` — Claude Code 設定。専用 skill・agents の正本と、共有 skill への symlink
- `.agents/skills/` — 共有 skill の正本 (vendored skill を含む)。Codex が探索し、`.claude/skills/` から symlink で参照する
- `.codex/` — Codex 用: `AGENTS.md.global` (グローバル指示)、`rules/` (command rules)、`agents/` (reviewer role TOML)。ルート `AGENTS.md` は `CLAUDE.md` への symlink

## シェル環境

- Zsh + **sheldon** (Rust 製プラグインマネージャ)
- プラグイン: completion, syntax-highlighting, autosuggestions, history-substring-search
- **Starship** プロンプト
- **peco**: `Ctrl+R` (履歴), `Ctrl+G` (ディレクトリ)

エイリアス: `.zshrc` (`ls`, `showz`, `editz`, `sourcez`, `be`, `ghql`, `dc`, `nf`, `ng`, `devc`) / `.gitconfig` (`st`, `co`, `br`, `cm`, `pr`, `lg`, `wa`, `wl`, `wr`)

## git worktree マネージャ (`wt`)

`.config/zsh/functions/wt.zsh` の Zsh 関数:

- `wt` — fzf で worktree 一覧。`Ctrl+D` で削除
- `wt add <branch>` — ブランチと worktree を新規作成
- `wt remove [-D] <branch>` — worktree とブランチを削除。`-D` 指定時のみ未コミット変更・未追跡ファイル・未マージのブランチも削除する。`main` / `master` と現在の worktree は削除しない
- `wt clean` — マージ済みブランチと worktree を一括削除 (対話確認あり)
- `wt init` — `.wt_hook.sh` テンプレート生成 (例: `.env` コピー、依存インストール)

`wt add` / `wt co` と Claude Code の作成 hook は、初期化を新しい worktree 内で `bash -e -o pipefail` により実行する。失敗時は非ゼロで終了し、調査・復旧のため worktree を残す。親シェルの環境変数は変更しない。

## MCP サーバー

`setup_claude_mcp.sh` で設定 (`claude mcp add`): **chrome-devtools**, **deepwiki**, **aws-mcp**

**playwright**, **context7** などは Claude Code のプラグイン (`@claude-plugins-official` 等) 経由で導入するため `setup_claude_mcp.sh` の管轄外。`/plugin install <name>@<marketplace>` で有効化する。

## セットアップ後の手順

1. 1Password にサインイン
2. `.gitconfig.local.sample` → `~/.gitconfig.local`
3. `.zsh_secrets.example` → `~/.zsh_secrets`
4. 再起動
