#!/bin/bash
# LLMitM Setup Script
# Checks dependencies, configures /etc/hosts, starts Juice Shop, prints next steps.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
fail() { echo -e "${RED}[-]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

errors=0

# --- Dependency checks ---
echo "Checking dependencies..."

# Node.js
if command -v node &>/dev/null; then
    node_ver=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$node_ver" -ge 20 ]; then
        ok "Node.js $(node --version)"
    else
        fail "Node.js $(node --version) — need v20+. Install: https://nodejs.org/"
        errors=$((errors + 1))
    fi
else
    fail "Node.js not found. Install v20+: https://nodejs.org/"
    errors=$((errors + 1))
fi

# Python 3
if command -v python3 &>/dev/null; then
    ok "Python3 $(python3 --version 2>&1 | awk '{print $2}')"
else
    fail "Python3 not found. Install: https://www.python.org/"
    errors=$((errors + 1))
fi

# mitmproxy (via pipx to avoid PEP 668 on modern distros)
if command -v mitmdump &>/dev/null; then
    ok "mitmproxy $(mitmdump --version 2>&1 | head -1 | awk '{print $2}')"
else
    warn "mitmproxy not found. Installing via pipx..."
    if ! command -v pipx &>/dev/null; then
        sudo apt-get install -y pipx 2>/dev/null || pip3 install --user pipx
        pipx ensurepath
    fi
    pipx install mitmproxy
    # Ensure pipx bin dir is on PATH for the rest of this script
    export PATH="$HOME/.local/bin:$PATH"
    ok "mitmproxy installed: $(mitmdump --version 2>&1 | head -1 | awk '{print $2}')"
fi

# Claude Code
if command -v claude &>/dev/null; then
    ok "Claude Code $(claude --version 2>/dev/null || echo '(version unknown)')"
else
    warn "Claude Code not found. Installing via native installer..."
    curl -fsSL https://claude.ai/install.sh | sh
    ok "Claude Code installed"
fi

# bubblewrap (Linux only)
if [[ "$(uname)" == "Linux" ]]; then
    if command -v bwrap &>/dev/null; then
        ok "bubblewrap (bwrap)"
    else
        warn "bubblewrap not found. Installing..."
        sudo apt-get install -y bubblewrap
        ok "bubblewrap installed"
    fi
fi

# socat (Linux only — needed for sandbox socket bridges)
if [[ "$(uname)" == "Linux" ]]; then
    if command -v socat &>/dev/null; then
        ok "socat"
    else
        warn "socat not found. Installing..."
        sudo apt-get install -y socat
        ok "socat installed"
    fi
fi

# sandbox-runtime (seccomp filter for Claude Code sandbox)
if npm list -g @anthropic-ai/sandbox-runtime &>/dev/null; then
    ok "sandbox-runtime (seccomp filter)"
else
    warn "sandbox-runtime not found. Installing..."
    npm install -g @anthropic-ai/sandbox-runtime
    ok "sandbox-runtime installed"
fi

# Docker
if command -v docker &>/dev/null; then
    ok "Docker $(docker --version 2>&1 | awk '{print $3}' | tr -d ',')"
else
    fail "Docker not found. Install: https://docs.docker.com/get-docker/"
    errors=$((errors + 1))
fi

if [ "$errors" -gt 0 ]; then
    echo ""
    fail "$errors missing dependency(ies) that cannot be auto-installed. Fix them and re-run."
    exit 1
fi

echo ""

# --- /etc/hosts entry ---
if grep -q 'juiceshop' /etc/hosts 2>/dev/null; then
    ok "/etc/hosts already has 'juiceshop' entry"
else
    echo "Adding '127.0.0.1 juiceshop' to /etc/hosts (requires sudo)..."
    echo "127.0.0.1 juiceshop" | sudo tee -a /etc/hosts >/dev/null
    ok "Added '127.0.0.1 juiceshop' to /etc/hosts"
fi

# --- Default settings ---
SETTINGS="mitmproxy-ai-tool/.claude/settings.json"
PROFILE="mitmproxy-ai-tool/.claude/settings-profiles/settings-development.json"
if [ -f "$SETTINGS" ]; then
    ok "Settings file exists: $SETTINGS"
else
    cp "$PROFILE" "$SETTINGS"
    ok "Copied default settings: $PROFILE → $SETTINGS"
fi

# --- Start Juice Shop ---
echo ""
echo "Starting Juice Shop..."
docker compose up -d

echo ""
echo "Waiting for Juice Shop to be ready..."
for i in $(seq 1 30); do
    if curl -sf http://juiceshop:3000/ >/dev/null 2>&1; then
        ok "Juice Shop is ready at http://juiceshop:3000"
        break
    fi
    if [ "$i" -eq 30 ]; then
        warn "Juice Shop not responding yet. It may still be starting — check: curl http://juiceshop:3000/"
    fi
    sleep 2
done

# --- Done ---
echo ""
echo "=========================================="
echo " LLMitM Setup Complete"
echo "=========================================="
echo ""
echo " 1. Set your API key:"
echo "    export CLAUDE_API_KEY=sk-ant-..."
echo ""
echo " 2. Launch the agent:"
echo "    cd mitmproxy-ai-tool && claude"
echo ""
echo " 3. Paste the hunt prompt (see README.md)"
echo ""
