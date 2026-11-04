# CLAUDE.md

このファイルは Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイドです。`AGENTS.md` はこのファイルへの symlink であり、Codex など他のエージェントも同じ内容を読む (Claude Code 固有の記述は該当製品以外では無視してよい)。

## 概要

macOS のセットアップと設定管理用の個人 dotfiles リポジトリ。Homebrew パッケージ管理、シェルスクリプトによる自動セットアップ、各種開発ツールの設定を含む。

個人リポジトリのため `main` への直接 push・直接変更を許可。PR レビューやフィーチャーブランチは不要。

**ブランチ運用方針はこのプロジェクト CLAUDE.md を優先する** — グローバル指示 (`~/.claude/CLAUDE.md` / `~/.codex/AGENTS.md`) の「main での作業禁止」ルールより、本プロジェクトの方針 (main での直接作業 OK) を採用する。

## 共有できない情報の持ち込み禁止

複数 PC で共有する公開リポジトリのため、他の PC と共有できない端末固有の設定や、個別プロジェクトの情報をコミット・push しない。この禁止事項は設定・コード・スクリプト・ドキュメント・指示ファイル・スキルなど、リポジトリ内の全ファイルに適用する。Issue・PR・コミットメッセージにも記録しない。

- 特定の PC のユーザー名やディレクトリ構成に依存する絶対パス、機器 ID、端末固有の接続先や設定値を含めない。
- 他のローカルリポジトリの名前・パス・ファイル構成・設定内容・作業の背景や経緯、リポジトリ別 hook を含めない。
- 認証情報・秘密情報、端末内の履歴や作業記録を含めない。

これらは Git 管理外のローカル設定や記録に分離する。アプリからの設定取り込み・自動保存を含め、コミット・push 前に差分を確認し、禁止対象が混入している場合は除外する。共有できるか判断できない情報はコミット・push しない。

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
- `.config/mise/config.toml` — mise (Node.js 26.12.1, Go 1.27.3, Ruby 3.2.2)
- `.gitconfig` — Git エイリアス。個人設定は `.gitconfig.local.sample` → `~/.gitconfig.local`
- `.zsh_secrets.example` → `~/.zsh_secrets` (秘密環境変数)
- `.config/nvim/`, `.config/wezterm/`, `.config/ghostty/`, `.config/cmux/`, `.config/lazygit/` — Neovim (Lua), WezTerm, Ghostty, cmux (JSONC), lazygit (delta pager)
- `.claude/` — Claude Code 設定。専用 skill・agents の正本と、共有 skill への symlink
- `.agents/skills/` — 共有 skill の正本 (vendored skill を含む)。Codex が探索し、`.claude/skills/` から symlink で参照する
- `.codex/` — Codex 用: `AGENTS.md.global` (グローバル指示)、`rules/` (command rules)、`agents/` (実装・レビュー等の role TOML)。ルート `AGENTS.md` は `CLAUDE.md` への symlink

## シェル環境

- Zsh + **sheldon** (Rust 製プラグインマネージャ)
- プラグイン: completion, syntax-highlighting, autosuggestions, history-substring-search
- **Starship** プロンプト
- **peco**: `Ctrl+R` (履歴), `Ctrl+G` (ディレクトリ)

エイリアス: `.zshrc` (`ls`, `showz`, `editz`, `sourcez`, `be`, `ghql`, `dc`, `nf`, `ng`, `devc`) / `.gitconfig` (`st`, `co`, `br`, `cm`, `pr`, `lg`, `wa`, `wl`, `wr`)

## Worktrunk

worktree の操作は [Worktrunk](https://worktrunk.dev/) に統一する。

個人用の初期化処理は各リポジトリの `.config/wt.toml` に置き、グローバル Git ignore でローカル管理する。チームで追跡済みの設定はそのまま利用する。ローカル設定は新しい PC へ自動では引き継がれない。

Git 管理外の設定は追加 worktree にも自動では引き継がれない。追加 worktree からも初期化を使う場合は、`pre-start` で設定自身をコピーする。

作業開始前に必要な初期化は `pre-start` に置く。設定と承認の仕様は [公式 hook 資料](https://worktrunk.dev/hook/) を参照する。

## MCP サーバー

`setup_claude_mcp.sh` で設定 (`claude mcp add`): **chrome-devtools**, **deepwiki**, **aws-mcp**

**playwright**, **context7** などは Claude Code のプラグイン (`@claude-plugins-official` 等) 経由で導入するため `setup_claude_mcp.sh` の管轄外。`/plugin install <name>@<marketplace>` で有効化する。

## セットアップ後の手順

1. 1Password にサインイン
2. `.gitconfig.local.sample` → `~/.gitconfig.local`
3. `.zsh_secrets.example` → `~/.zsh_secrets`
4. 再起動
