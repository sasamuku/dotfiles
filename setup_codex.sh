#!/bin/sh
set -eu

# Codex CLI Setup Script
# 正本は .claude/ と .codex/ (dotfiles repo)。Codex にはグローバル指示・rules・agent role・共有 skill を symlink で公開する。
# ~/.codex/config.toml, auth.json, sessions 等の Codex 自己管理ファイルには一切触れない。
# 前提: setup_dotfiles.sh の Claude セットアップ済み (agent role が ~/.claude/agents, ~/.claude/skills を参照するため)

echo "🔧 Setting up Codex CLI configuration..."

DOTFILES_DIR=$(realpath $(dirname ${0}))

if [ ! -e ~/.claude/agents ] || [ ! -e ~/.claude/skills ]; then
  echo "  ⚠️  ~/.claude/agents or ~/.claude/skills not found. Run setup_dotfiles.sh first (reviewer roles depend on them)"
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
mkdir -p ~/.codex/agents
for role in "${DOTFILES_DIR}"/.codex/agents/*.toml; do
  link_owned "${role}" ~/.codex/agents/"$(basename "${role}")"
done

# Shared skills (per-skill symlink, 他ツール管理の既存エントリは上書きしない)
echo "📁 Linking shared skills into ~/.agents/skills..."
mkdir -p ~/.agents/skills
for skill in "${DOTFILES_DIR}"/.agents/skills/*/; do
  name=$(basename "${skill}")
  target=~/.agents/skills/${name}
  if [ -L "${target}" ]; then
    case "$(readlink "${target}")" in
      "${DOTFILES_DIR}"/*) ln -sfn "${DOTFILES_DIR}/.agents/skills/${name}" "${target}" ;;
      *) echo "  ⚠️  Skip ${name}: exists (managed elsewhere)" ;;
    esac
  elif [ -e "${target}" ]; then
    echo "  ⚠️  Skip ${name}: exists (real directory)"
  else
    ln -s "${DOTFILES_DIR}/.agents/skills/${name}" "${target}"
  fi
done

echo "✅ Codex setup completed!"
