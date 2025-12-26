#!/bin/bash
# =============================================================================
# Permission Fixer - Runtime Script for Agent Use
# =============================================================================
# This script can be run INSIDE the container if permission issues occur
# during agent operation. It fixes all writable paths that the agent needs.
#
# Usage (inside container):
#   bash /workspace/.claude/scripts/fix-permissions.sh
#
# What it fixes:
#   - Memory files (session.md, hypotheses.md, findings.md)
#   - .claude/scripts/ directory for addon creation
#   - .claude/agents/ directory for system prompts
#   - captures/ and certs/ directories for traffic and certificates
#   - .git/ directory for git operations
#
# =============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verify we're inside container
if [ ! -d "/workspace" ]; then
    log_error "This script must be run INSIDE the container"
    echo "Run: docker compose -f ATOMIC/docker-compose.yml exec llmitm bash"
    exit 1
fi

echo -e "${BLUE}=== Permission Fixer (Inside Container) ===${NC}"
echo ""

WORKSPACE="/workspace"

# Fix #1: Memory files
log_info "Fixing memory file permissions..."
mkdir -p "$WORKSPACE/.claude/memory"
touch "$WORKSPACE/.claude/memory/session.md" 2>/dev/null || true
touch "$WORKSPACE/.claude/memory/hypotheses.md" 2>/dev/null || true
touch "$WORKSPACE/.claude/memory/findings.md" 2>/dev/null || true
touch "$WORKSPACE/.claude/memory/task.json" 2>/dev/null || true
chmod 644 "$WORKSPACE/.claude/memory/"*.md "$WORKSPACE/.claude/memory/"*.json 2>/dev/null || true
log_success "Memory files OK"

# Fix #2: .claude/scripts/ directory
log_info "Fixing .claude/scripts/ directory..."
mkdir -p "$WORKSPACE/.claude/scripts"
chmod 755 "$WORKSPACE/.claude/scripts"
log_success ".claude/scripts/ OK"

# Fix #3: .claude/agents/ directory
log_info "Fixing .claude/agents/ directory..."
mkdir -p "$WORKSPACE/.claude/agents"
chmod 755 "$WORKSPACE/.claude/agents"
log_success ".claude/agents/ OK"

# Fix #4: captures directory
log_info "Fixing captures/ directory..."
mkdir -p "$WORKSPACE/captures"
chmod 755 "$WORKSPACE/captures"
log_success "captures/ OK"

# Fix #5: certs directory
log_info "Fixing certs/ directory..."
mkdir -p "$WORKSPACE/certs"
chmod 755 "$WORKSPACE/certs"
log_success "certs/ OK"

# Fix #6: Hook scripts (if accessible)
log_info "Fixing hook script permissions..."
if [ -d "$WORKSPACE/.claude/hooks" ]; then
    chmod u+x "$WORKSPACE/.claude/hooks/"*.sh 2>/dev/null || true
    log_success "Hook scripts OK"
else
    log_warn "Hook scripts not in writable mount (expected - security boundary)"
fi

# Fix #7: Workspace ownership (if vscode user has sudo)
log_info "Attempting to fix workspace ownership to vscode:vscode..."
if sudo -n true 2>/dev/null; then
    # sudo available without password
    sudo chown -R 1000:1000 "$WORKSPACE" 2>/dev/null || {
        log_warn "Could not chown (may require password)"
    }
    log_success "Workspace ownership fixed"
else
    log_warn "sudo requires password (skipping ownership fix)"
    log_info "If you see 'Permission denied' errors, run: sudo chown -R 1000:1000 /workspace"
fi

# Summary
echo ""
echo -e "${GREEN}=== All fixable permissions have been reset ===${NC}"
echo ""
echo "If you still see permission errors, they may be:"
echo "  1. Named volumes (captures/certs) owned by root - requires host-side fix"
echo "  2. Read-only mounts (.claude/hooks/, .claude/settings.json) - expected"
echo "  3. Files not yet created during container startup"
echo ""
echo "Contact the maintainer if issues persist."
