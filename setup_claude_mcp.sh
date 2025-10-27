#!/bin/sh

# Claude MCP Setup Script
# Sets up MCP servers for Claude Code since MCP configurations cannot be shared via dotfiles

echo "🔧 Setting up Claude MCP servers..."

# Check if Claude CLI is available
CLAUDE_PATH=$(which claude)
if [ -z "$CLAUDE_PATH" ]; then
    echo "❌ Claude CLI not found in PATH. Please install Claude Code first."
    exit 1
fi

# Add MCP servers (user scope)
MCP_LIST=$("$CLAUDE_PATH" mcp list 2>/dev/null || echo "")

echo "➕ Adding chrome-devtools MCP server..."
if echo "$MCP_LIST" | grep -q "chrome-devtools"; then
    echo "   ⏭️  chrome-devtools already exists, skipping..."
else
    "$CLAUDE_PATH" mcp add chrome-devtools --scope user -- npx chrome-devtools-mcp@latest
fi

echo "➕ Adding context7 MCP server..."
if echo "$MCP_LIST" | grep -q "context7"; then
    echo "   ⏭️  context7 already exists, skipping..."
else
    "$CLAUDE_PATH" mcp add --transport http --scope user context7 https://mcp.context7.com/mcp
fi

echo "➕ Adding serena MCP server..."
if echo "$MCP_LIST" | grep -q "serena"; then
    echo "   ⏭️  serena already exists, skipping..."
else
    "$CLAUDE_PATH" mcp add serena --scope user -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant
fi

echo "🎉 Claude MCP setup completed!"
echo ""
echo "📋 Current MCP servers:"
"$CLAUDE_PATH" mcp list
