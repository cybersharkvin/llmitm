#!/bin/bash
# llmitm-juiceshop.sh - Spawn llmitm agent for Juice Shop testing
#
# Prerequisites:
#   1. Juice Shop running: docker run --rm -p 127.0.0.1:3000:3000 bkimminich/juice-shop
#   2. mitmdump installed: pip install mitmproxy
#   3. Claude Code installed
#
# Usage: ./llmitm-juiceshop.sh

set -e

# cd to script's directory (mitmproxy-ai-tool/)
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== LLMITM Bug Bounty Hunter ==="
echo "Target: OWASP Juice Shop (localhost:3000)"
echo ""

# Check prerequisites
if ! command -v mitmdump &> /dev/null; then
    echo "ERROR: mitmdump not found. Install with: pip install mitmproxy"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo "ERROR: claude CLI not found."
    exit 1
fi

# Spawn Claude headless (already in mitmproxy-ai-tool/)
claude -p "Target: OWASP Juice Shop at localhost:3000. Read your playbook @CLAUDE.md and memory files @.claude/memory/, then begin the bug bounty workflow. Update memory files as you work."
