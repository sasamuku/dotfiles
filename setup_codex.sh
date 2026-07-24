#!/bin/sh

# Codex CLI Setup Script
# 正本は .claude/ と .codex/ (dotfiles repo)。Codex にはグローバル指示・rules・共有 skill を symlink で公開する。
# ~/.codex/config.toml, auth.json, sessions 等の Codex 自己管理ファイルには一切触れない。

echo "🔧 Setting up Codex CLI configuration..."

DOTFILES_DIR=$(realpath $(dirname ${0}))

# Global instructions
echo "📝 Creating Codex global AGENTS.md symlink..."
mkdir -p ~/.codex
ln -sfn ${DOTFILES_DIR}/.codex/AGENTS.md.global ~/.codex/AGENTS.md

# Command rules
echo "🛡️  Creating Codex rules symlink..."
mkdir -p ~/.codex/rules
ln -sfn ${DOTFILES_DIR}/.codex/rules/dotfiles.rules ~/.codex/rules/dotfiles.rules

# Shared skills (per-skill symlink, 既存エントリは上書きしない)
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
echo "  Note: .codex/agents/*.toml (reviewer roles) はプロジェクト内でのみ有効。他リポジトリで使う場合は ~/.codex/config.toml の [agents] に手動登録する"
