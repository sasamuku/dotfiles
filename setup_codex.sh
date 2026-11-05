#!/bin/sh
set -eu

# Codex CLI Setup Script
# 正本は .agents/skills/ (共有 skill)、.claude/ (Claude 設定)、.codex/ (Codex 設定)。Codex へ symlink で公開する。
# agent role と共有 skill はディレクトリごとリンクする。Codex は agent role のファイル自体が symlink だと読まない (O_NOFOLLOW)。
# ~/.codex/config.toml, auth.json, sessions 等の Codex 自己管理ファイルには一切触れない。
# 前提: setup_dotfiles.sh の Claude セットアップ済み (agent role が ~/.claude/agents, ~/.claude/skills を参照するため)

echo "🔧 Setting up Codex CLI configuration..."

DOTFILES_DIR=$(realpath "$(dirname "$0")")

if [ ! -e ~/.claude/agents ] || [ ! -e ~/.claude/skills ]; then
  echo "  ❌ ~/.claude/agents or ~/.claude/skills not found. Run setup_dotfiles.sh first (reviewer roles depend on them)" >&2
  exit 1
fi

# dotfiles 管理のリンクを冪等に張る。管理外の symlink はスキップ、手書きファイル/ディレクトリはバックアップして置換
link_owned() {
  src=$1; dst=$2
  if [ -L "${dst}" ]; then
    case "$(readlink "${dst}")" in
      "${DOTFILES_DIR}"/*) ;;
      *) echo "  ⚠️  Skip ${dst}: symlink managed elsewhere ($(readlink "${dst}"))"; return 0 ;;
    esac
  elif [ -e "${dst}" ]; then
    backup="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "${dst}" "${backup}"
    echo "  📦 Backed up existing ${dst} to ${backup}"
  fi
  ln -sfn "${src}" "${dst}"
}

# ディレクトリごと dotfiles にリンクする。実ディレクトリが残っていれば、中の dotfiles 管理の symlink と .DS_Store を消し、
# 空になれば削除、ほかのものが残れば link_owned がディレクトリごと退避する
link_dir() {
  src=$1; dst=$2
  if [ -d "${dst}" ] && [ ! -L "${dst}" ]; then
    for entry in "${dst}"/* "${dst}"/.[!.]*; do
      [ -L "${entry}" ] || continue
      case "$(readlink "${entry}")" in
        "${DOTFILES_DIR}"/*) rm "${entry}" ;;
      esac
    done
    rm -f "${dst}/.DS_Store"
    rmdir "${dst}" 2>/dev/null && echo "  🧹 Replaced per-entry links in ${dst} with a directory link"
  fi
  link_owned "${src}" "${dst}"
}

# Global instructions
echo "📝 Creating Codex global AGENTS.md symlink..."
mkdir -p ~/.codex
link_owned "${DOTFILES_DIR}/.codex/AGENTS.md.global" ~/.codex/AGENTS.md

# Command rules
echo "🛡️  Creating Codex rules symlink..."
mkdir -p ~/.codex/rules
link_owned "${DOTFILES_DIR}/.codex/rules/dotfiles.rules" ~/.codex/rules/dotfiles.rules

# Agent roles (~/.codex/agents は $CODEX_HOME/agents として自動探索される)
echo "🤖 Linking Codex agent roles..."
link_dir "${DOTFILES_DIR}/.codex/agents" ~/.codex/agents

# Shared skills (npx skills add -g などのグローバル導入は dotfiles の .agents/skills に入る)
echo "📁 Linking shared skills into ~/.agents/skills..."
mkdir -p ~/.agents
link_owned "${DOTFILES_DIR}/.agents/.skill-lock.json" ~/.agents/.skill-lock.json
link_dir "${DOTFILES_DIR}/.agents/skills" ~/.agents/skills

# Account switcher (all account names, homes and selection remain local).
mkdir -p ~/.local/bin ~/.config/zsh/functions
for entry in ".local/bin/cxs" ".config/zsh/functions/codex.zsh"; do
  dst="$HOME/$entry"
  src="$DOTFILES_DIR/$entry"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    :
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "  ⚠️  Skip $dst: already exists"
  else
    ln -s "$src" "$dst"
  fi
done

# Codex は agent role の toml 自体が symlink だと読まず、spawn_agent が "agent type is currently not available" で失敗する。
# 共有の ~/.codex/agents と、CXS の各アカウントの agents に残っていないかを確かめる
python3 - <<'PY'
import json
from pathlib import Path

home = Path.home()
dirs = [home / '.codex/agents']
registry = home / '.config/codex-accounts/accounts.json'
if registry.exists():
    dirs += [Path(p).expanduser() / 'agents' for p in json.loads(registry.read_text())['accounts'].values()]
for d in dirs:
    for f in sorted(d.glob('**/*.toml')):
        if f.is_symlink():
            print(f'  ⚠️  Codex cannot load a symlinked agent role: {f}')
PY

echo "✅ Codex setup completed!"
