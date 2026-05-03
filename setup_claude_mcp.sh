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

echo "➕ Adding deepwiki MCP server..."
if echo "$MCP_LIST" | grep -q "deepwiki"; then
    echo "   ⏭️  deepwiki already exists, skipping..."
else
    "$CLAUDE_PATH" mcp add --scope user --transport http deepwiki https://mcp.deepwiki.com/mcp
fi

echo "➕ Adding aws-mcp MCP server..."
if echo "$MCP_LIST" | grep -q "aws-mcp"; then
    echo "   ⏭️  aws-mcp already exists, skipping..."
else
    "$CLAUDE_PATH" mcp add aws-mcp --scope user -- uvx mcp-proxy-for-aws@latest https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=ap-northeast-1
fi

echo "🎉 Claude MCP setup completed!"
echo ""
echo "📋 Current MCP servers:"
"$CLAUDE_PATH" mcp list
