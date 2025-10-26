#!/bin/sh

# Claude MCP Setup Script
# Sets up MCP servers for Claude Code since MCP configurations cannot be shared via dotfiles

echo "🔧 Setting up Claude MCP servers..."

# Check if Claude CLI is available
CLAUDE_PATH="$HOME/.claude/local/claude"
if [ ! -f "$CLAUDE_PATH" ]; then
    echo "❌ Claude CLI not found at $CLAUDE_PATH. Please install Claude Code first."
    exit 1
fi

# Add MCP servers (user scope)
echo "➕ Adding chrome-devtools MCP server..."
"$CLAUDE_PATH" mcp add chrome-devtools --scope user -- npx chrome-devtools-mcp@latest

echo "➕ Adding context7 MCP server..."
"$CLAUDE_PATH" mcp add --transport http --scope user context7 https://mcp.context7.com/mcp

echo "➕ Adding serena MCP server..."
"$CLAUDE_PATH" mcp add serena --scope user -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant

echo "🎉 Claude MCP setup completed!"
echo ""
echo "📋 Current MCP servers:"
"$CLAUDE_PATH" mcp list
