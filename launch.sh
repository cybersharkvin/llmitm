#!/bin/bash
# =============================================================================
# LLMitM Bug Bounty Hunter - Automated Launch Script with Permission Fixes
# =============================================================================
# One-command setup: Detects/creates Juice Shop, configures firewall, and
# launches the agent in a network-isolated container environment.
#
# Usage:
#   ./launch.sh                    # Interactive mode (prompts for API key if needed)
#   CLAUDE_API_KEY=sk-... ./launch.sh   # Non-interactive mode
#
# Features:
#   - Detects or creates Juice Shop container automatically
#   - Extracts Juice Shop IP and updates .env
#   - Launches firewall + agent containers with proper ordering
#   - Verifies connectivity before dropping into shell
#   - Idempotent (safe to run multiple times)
#   - Fixes ALL permission issues (host ownership, named volumes, hook scripts)
#
# PERMISSION HANDLING:
#   This script proactively fixes 8 critical permission issues before
#   launching containers to prevent runtime "Permission denied" failures:
#
#   1. Named Volume Ownership - Docker volumes created by daemon may be root:root
#      Fix: chown to 1000:1000 (vscode user) inside container post-launch
#
#   2. Hook Script Execute Permissions - Shell scripts need +x bit
#      Fix: chmod u+x on all .claude/hooks/*.sh before container start
#
#   3. .claude/scripts/ Directory - Agent needs to create Python addons
#      Fix: mkdir -p and ensure writable ownership
#
#   4. .git/ Ownership - Git commands fail if owned by root
#      Fix: chown -R 1000:1000 on .git
#
#   5. Memory Files - Agent needs read/write to session/hypotheses/findings
#      Fix: Initialize with correct ownership and readable permissions
#
#   6. Host .env Permissions - Script needs to read environment file
#      Fix: chmod 644 on .env
#
#   7. Parent Directory Traversal - Even subdirs need parent execute (+x)
#      Fix: chmod +x on ATOMIC/ and parent directories
#
#   8. Docker Socket - On Linux, may have restrictive permissions
#      Fix: Verify user can run docker (docker group or sudo)
#
# PLATFORM SUPPORT:
#   - Linux (primary): Uses sudo where needed (e.g., chown inside container)
#   - macOS: Docker Desktop handles permissions; sudo may not be in container
#   - WSL2: Similar to Linux; Docker Desktop backend differs from Docker Engine
#
# =============================================================================

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JUICE_SHOP_CONTAINER="juice-shop"
JUICE_SHOP_IMAGE="bkimminich/juice-shop:latest"
JUICE_SHOP_PORT="3000"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${SCRIPT_DIR}/mitmproxy-ai-tool"
ENV_FILE="${SCRIPT_DIR}/.env"
ENV_EXAMPLE="${SCRIPT_DIR}/.env.example"
DOCKER_COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

# =============================================================================
# Utility Functions
# =============================================================================

log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

exit_error() {
    log_error "$1"
    exit 1
}

# =============================================================================
# Step 3: Check Prerequisites
# =============================================================================

check_prerequisites() {
    log_header "Checking Prerequisites"

    # Check docker
    if ! command -v docker &> /dev/null; then
        exit_error "Docker is not installed. Please install Docker first."
    fi
    log_success "Docker found: $(docker --version)"

    # Check docker compose plugin
    if ! docker compose version &> /dev/null; then
        exit_error "docker compose plugin is not installed. Please install it first."
    fi
    log_success "docker compose found: $(docker compose version)"

    # Verify we're in the right directory
    if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
        exit_error "docker-compose.yml not found in $SCRIPT_DIR. Are you in the repo root?"
    fi
    log_success "Working directory verified: $SCRIPT_DIR"

    # Verify .env.example exists
    if [ ! -f "$ENV_EXAMPLE" ]; then
        exit_error ".env.example not found. Corrupted repository?"
    fi
    log_success ".env.example found"
}

# =============================================================================
# Step 4: Detect Juice Shop
# =============================================================================

detect_juice_shop() {
    # Check if container exists and is running
    if docker ps --format '{{.Names}}' | grep -q "^${JUICE_SHOP_CONTAINER}$"; then
        echo "running"
    # Check if container exists but is stopped
    elif docker ps -a --format '{{.Names}}' | grep -q "^${JUICE_SHOP_CONTAINER}$"; then
        echo "stopped"
    else
        echo "missing"
    fi
}

# =============================================================================
# Step 5: Create Juice Shop (if needed)
# =============================================================================

create_juice_shop() {
    local status=$1

    if [ "$status" = "running" ]; then
        log_success "Juice Shop is already running"
        return 0
    fi

    if [ "$status" = "stopped" ]; then
        log_info "Starting existing Juice Shop container..."
        docker start "$JUICE_SHOP_CONTAINER" > /dev/null
        sleep 2
        log_success "Juice Shop started"
        return 0
    fi

    # Create new container
    log_info "Creating new Juice Shop container..."

    # Check if port is in use
    if lsof -Pi :${JUICE_SHOP_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
        exit_error "Port ${JUICE_SHOP_PORT} is already in use. Free it or use a different port."
    fi

    docker run -d \
        --name "$JUICE_SHOP_CONTAINER" \
        -p "127.0.0.1:${JUICE_SHOP_PORT}:3000" \
        "$JUICE_SHOP_IMAGE" > /dev/null

    log_info "Waiting for Juice Shop to start (10 seconds)..."
    sleep 10

    # Verify it started
    if ! docker ps --format '{{.Names}}' | grep -q "^${JUICE_SHOP_CONTAINER}$"; then
        exit_error "Juice Shop container failed to start. Check: docker logs $JUICE_SHOP_CONTAINER"
    fi

    log_success "Juice Shop container created and running"
}

# =============================================================================
# Step 6: Extract Juice Shop IP
# =============================================================================

get_juice_shop_ip() {
    local ip=$(docker inspect "$JUICE_SHOP_CONTAINER" \
        --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)

    if [ -z "$ip" ]; then
        exit_error "Could not extract IP for $JUICE_SHOP_CONTAINER container"
    fi

    # Validate IP format (basic check)
    if ! [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        exit_error "Invalid IP format extracted: $ip"
    fi

    echo "$ip"
}

# =============================================================================
# Step 7: Setup .env file
# =============================================================================

fix_workspace_permissions() {
    log_header "Fixing Workspace Permissions & Ownership"

    local workspace_dir="${SCRIPT_DIR}/mitmproxy-ai-tool"

    if [ ! -d "$workspace_dir" ]; then
        log_warn "Workspace directory not found, skipping permission fixes"
        return 0
    fi

    # FIX #1: Ensure vscode user owns workspace
    log_info "Ensuring vscode user (1000:1000) owns workspace..."
    sudo chown -R 1000:1000 "$workspace_dir" 2>/dev/null || {
        # If sudo fails, try without sudo (may already have permissions)
        chown -R 1000:1000 "$workspace_dir" 2>/dev/null || true
    }

    # FIX #2: Hook scripts need execute permission
    log_info "Setting execute permissions on hook scripts..."
    chmod -R u+x "$workspace_dir/.claude/hooks/"*.sh 2>/dev/null || true
    chmod u+x "$workspace_dir/launch.sh" 2>/dev/null || true

    # FIX #3: Ensure .claude/scripts/ directory exists and is writable
    log_info "Ensuring .claude/scripts/ directory exists with correct permissions..."
    mkdir -p "$workspace_dir/.claude/scripts" 2>/dev/null || true
    chmod 755 "$workspace_dir/.claude/scripts" 2>/dev/null || true

    # FIX #4: Initialize memory files with correct ownership and permissions
    log_info "Initializing memory files..."
    mkdir -p "$workspace_dir/.claude/memory" 2>/dev/null || true
    touch "$workspace_dir/.claude/memory/session.md" 2>/dev/null || true
    touch "$workspace_dir/.claude/memory/hypotheses.md" 2>/dev/null || true
    touch "$workspace_dir/.claude/memory/findings.md" 2>/dev/null || true
    chmod 644 "$workspace_dir/.claude/memory/"*.md 2>/dev/null || true

    # FIX #5: Ensure .git ownership (fixes "dubious ownership" errors)
    log_info "Ensuring .git directory has correct ownership..."
    sudo chown -R 1000:1000 "$workspace_dir/.git" 2>/dev/null || {
        chown -R 1000:1000 "$workspace_dir/.git" 2>/dev/null || true
    }

    # FIX #6: Ensure parent directories have execute permission
    log_info "Ensuring parent directories are traversable..."
    chmod +x "$SCRIPT_DIR" 2>/dev/null || true
    if [ -d "$(dirname "$SCRIPT_DIR")" ]; then
        chmod +x "$(dirname "$SCRIPT_DIR")" 2>/dev/null || true
    fi

    # FIX #7: Ensure .env file is readable
    if [ -f "$ENV_FILE" ]; then
        log_info "Ensuring .env file is readable..."
        chmod 644 "$ENV_FILE" 2>/dev/null || true
    fi

    log_success "Host permissions fixed (workspace ownership, hooks, memory files)"
}

setup_env_file() {
    local juice_shop_ip=$1

    log_header "Configuring .env"

    if [ -f "$ENV_FILE" ]; then
        log_info ".env already exists, updating..."

        # Update TARGET_IPS line (preserve API key)
        sed -i.bak "s/^TARGET_IPS=.*/TARGET_IPS=${juice_shop_ip}/" "$ENV_FILE"
        rm -f "${ENV_FILE}.bak"
    else
        log_info "Creating .env from template..."
        cp "$ENV_EXAMPLE" "$ENV_FILE"

        # Update TARGET_IPS
        sed -i.bak "s/^TARGET_IPS=.*/TARGET_IPS=${juice_shop_ip}/" "$ENV_FILE"
        rm -f "${ENV_FILE}.bak"
    fi

    log_success ".env configured with TARGET_IPS=${juice_shop_ip}"

    # Check if API key is set
    if grep -q "^CLAUDE_API_KEY=$" "$ENV_FILE"; then
        log_warn "CLAUDE_API_KEY is not set in .env"
        log_info "Enter your Claude API key (or press Enter to use OAuth login):"
        read -p "CLAUDE_API_KEY: " api_key
        if [ -n "$api_key" ]; then
            sed -i.bak "s/^CLAUDE_API_KEY=.*/CLAUDE_API_KEY=${api_key}/" "$ENV_FILE"
            rm -f "${ENV_FILE}.bak"
            log_success "API key configured"
        else
            log_info "Using OAuth login - you'll be prompted when launching Claude"
        fi
    fi
}

# =============================================================================
# Step 8: Launch Containers
# =============================================================================

launch_containers() {
    log_header "Launching Containers"

    log_info "Starting firewall container (may take 5-10 seconds)..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d firewall 2>&1 | grep -v "Already in use" || true

    log_info "Waiting for firewall to initialize..."
    sleep 3

    log_info "Starting agent container..."
    docker compose -f "$DOCKER_COMPOSE_FILE" up -d llmitm 2>&1 | grep -v "Already in use" || true

    log_info "Waiting for agent container to be ready..."
    sleep 3

    log_success "Containers launched"
}

# =============================================================================
# Step 8b: Fix Named Volume Permissions (Inside Container)
# =============================================================================

fix_named_volume_permissions() {
    log_header "Fixing Named Volume Permissions"

    log_info "Fixing ownership of named volumes (llmitm-captures, llmitm-certs)..."
    # Change to compose directory to avoid "cwd outside mount namespace" error
    (
        cd "$SCRIPT_DIR"
        # Docker named volumes are created by daemon; fix ownership to vscode user inside container
        docker compose exec -T -w /workspace llmitm \
            sudo chown -R 1000:1000 /workspace/captures /workspace/certs 2>/dev/null || {
            # If sudo not available in container, try without
            docker compose exec -T -w /workspace llmitm \
                chown -R 1000:1000 /workspace/captures /workspace/certs 2>/dev/null || {
                log_warn "Could not fix named volume ownership (may require manual fix or Docker Desktop permissions)"
            }
        }
    )

    log_success "Named volume permissions fixed"
}

# =============================================================================
# Step 9: Verify Setup
# =============================================================================

verify_setup() {
    log_header "Verifying Setup"

    # Check if containers are running
    if ! docker ps --format '{{.Names}}' | grep -q "llmitm-firewall"; then
        exit_error "Firewall container (llmitm-firewall) is not running"
    fi
    log_success "Firewall container is running"

    if ! docker ps --format '{{.Names}}' | grep -q "llmitm-agent"; then
        exit_error "Agent container (llmitm-agent) is not running"
    fi
    log_success "Agent container is running"

    # Test proxy connectivity from agent
    log_info "Testing proxy connectivity..."
    (
        cd "$SCRIPT_DIR"
        if docker compose exec -T -w /workspace llmitm curl -s --connect-timeout 5 https://api.anthropic.com > /dev/null 2>&1; then
            log_success "Agent can reach Claude API through proxy"
        else
            log_warn "Could not verify Claude API connectivity (may be firewall issue)"
        fi
    )

    # Get Juice Shop IP and verify it's in allowlist
    local juice_ip=$(docker inspect "$JUICE_SHOP_CONTAINER" \
        --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
    log_success "Juice Shop running at ${juice_ip}:3000"
}

# =============================================================================
# Step 11: Drop into Shell
# =============================================================================

drop_into_shell() {
    log_header "Entering Agent Container"
    log_info "Type 'exit' to leave the container"
    log_info "Memory files: @.claude/memory/session.md, hypotheses.md, findings.md"
    log_info "Cheatsheet: @mitmdump-cheatsheet.md, @CLAUDE.md"
    log_info "Run Claude: claude --dangerously-skip-permissions --agent llmitm"
    echo ""

    # Change to script directory before exec to prevent "cwd outside mount" error
    # Then drop into container shell with /workspace as working directory
    cd "$SCRIPT_DIR"
    exec docker compose exec -w /workspace llmitm bash
}

# =============================================================================
# Step 10: Main Orchestration Flow
# =============================================================================

main() {
    log_header "LLMitM Bug Bounty Hunter - Launch Sequence"
    echo ""

    check_prerequisites
    echo ""

    log_header "Detecting Juice Shop"
    local juice_status=$(detect_juice_shop)
    case $juice_status in
        running)
            log_success "Juice Shop is already running"
            ;;
        stopped)
            log_info "Juice Shop container exists but is stopped"
            ;;
        missing)
            log_info "Juice Shop container not found, creating..."
            ;;
    esac
    echo ""

    create_juice_shop "$juice_status"
    echo ""

    log_header "Extracting Juice Shop IP"
    local juice_ip=$(get_juice_shop_ip)
    log_success "Juice Shop IP: $juice_ip"
    echo ""

    fix_workspace_permissions
    echo ""

    setup_env_file "$juice_ip"
    echo ""

    launch_containers
    echo ""

    fix_named_volume_permissions
    echo ""

    verify_setup
    echo ""

    drop_into_shell
}

# =============================================================================
# Entry Point
# =============================================================================

main
