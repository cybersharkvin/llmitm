#!/bin/bash
# =============================================================================
# LLMitM Bug Bounty Hunter - Cleanup Script
# =============================================================================
# Removes all containers, images, networks, and volumes created by launch.sh
#
# Usage:
#   ./cleanup.sh                 # Interactive (prompts for confirmation)
#   ./cleanup.sh --force         # Non-interactive (no prompts)
#   ./cleanup.sh --keep-volumes  # Keep data volumes (captures, certs)
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE_MODE=false
KEEP_VOLUMES=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_MODE=true
            shift
            ;;
        --keep-volumes)
            KEEP_VOLUMES=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./cleanup.sh [--force] [--keep-volumes]"
            exit 1
            ;;
    esac
done

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

# =============================================================================
# Confirmation Prompt
# =============================================================================

confirm() {
    if [ "$FORCE_MODE" = true ]; then
        return 0
    fi

    local prompt="$1"
    local response

    echo -en "${YELLOW}${prompt} (yes/no): ${NC}"
    read -r response

    if [ "$response" = "yes" ]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# Cleanup Functions
# =============================================================================

cleanup_containers() {
    log_header "Stopping & Removing Containers"

    local containers_to_remove=""

    # Method 1: Find by container name (handles docker-compose project name prefixes)
    # Matches: llmitm-agent, llmitm-firewall, atomic-llmitm-1, llmitm_llmitm_1, etc.
    local by_name
    by_name=$(docker ps -a --format '{{.Names}}' | grep -E "(llmitm|juice-shop)" || true)

    # Method 2: Find containers using llmitm volumes (catches VS Code devcontainers with random names)
    local by_volume=""
    for vol in llmitm-captures llmitm-certs; do
        if docker volume ls --format '{{.Name}}' | grep -qE "^.*${vol}$"; then
            by_volume="${by_volume} $(docker ps -a --filter volume="${vol}" --format '{{.Names}}' 2>/dev/null || true)"
        fi
    done

    # Method 3: Find by image name containing llmitm or mitmproxy
    local by_image
    by_image=$(docker ps -a --format '{{.Names}} {{.Image}}' | grep -E "(llmitm|mitmproxy)" | awk '{print $1}' || true)

    # Combine and deduplicate
    containers_to_remove=$(echo "$by_name $by_volume $by_image" | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')

    if [ -z "$(echo "$containers_to_remove" | tr -d ' ')" ]; then
        log_info "No llmitm containers found"
        return 0
    fi

    for container in $containers_to_remove; do
        log_info "Removing container: $container"
        if docker rm -f "$container" 2>/dev/null; then
            log_success "Removed container: $container"
        else
            log_warn "Failed to remove container: $container"
        fi
    done
}

cleanup_images() {
    log_header "Removing Images"

    # Find ALL llmitm-related images (handles docker-compose project name prefixes)
    # Matches: atomic-llmitm, atomic-firewall, llmitm_agent, etc.
    local images_to_remove
    images_to_remove=$(docker images --format '{{.Repository}}' | grep -E "(atomic|llmitm)" | sort -u || true)

    if [ -z "$images_to_remove" ]; then
        log_info "No llmitm images found"
        return 0
    fi

    for image in $images_to_remove; do
        log_info "Removing image: $image"
        if docker rmi -f "$image" 2>/dev/null; then
            log_success "Removed image: $image"
        else
            log_warn "Failed to remove image: $image"
        fi
    done
}

cleanup_networks() {
    log_header "Removing Networks"

    # Find ALL llmitm-related networks (handles docker-compose project name prefixes)
    # Matches: atomic_internal, atomic_external, llmitm_internal, atomic-default, etc.
    local networks_to_remove
    networks_to_remove=$(docker network ls --format '{{.Name}}' | grep -E "(atomic|llmitm)_(internal|external|default)" || true)

    if [ -z "$networks_to_remove" ]; then
        log_info "No llmitm networks found"
        return 0
    fi

    for network in $networks_to_remove; do
        log_info "Removing network: $network"
        if docker network rm "$network" 2>/dev/null; then
            log_success "Removed network: $network"
        else
            log_warn "Failed to remove network: $network (may have active endpoints)"
        fi
    done
}

cleanup_volumes() {
    log_header "Removing Volumes"

    if [ "$KEEP_VOLUMES" = true ]; then
        log_info "Skipping volume cleanup (--keep-volumes flag set)"
        return 0
    fi

    # Find ALL llmitm volumes (docker-compose prefixes with project name)
    # This catches: llmitm-captures, atomic_llmitm-captures, llmitm_llmitm-captures, etc.
    local volumes_to_remove
    volumes_to_remove=$(docker volume ls --format '{{.Name}}' | grep -E "llmitm-(captures|certs)$" || true)

    if [ -z "$volumes_to_remove" ]; then
        log_info "No llmitm volumes found"
        return 0
    fi

    for volume in $volumes_to_remove; do
        log_info "Removing volume: $volume"
        if docker volume rm "$volume" 2>/dev/null; then
            log_success "Removed volume: $volume"
        else
            log_warn "Failed to remove volume: $volume (may be in use)"
        fi
    done
}

cleanup_env() {
    log_header "Cleaning Up .env File"

    local env_file="${SCRIPT_DIR}/.env"

    if [ -f "$env_file" ]; then
        if confirm "Delete ${env_file}?"; then
            rm -f "$env_file"
            log_success "Removed .env file"
        else
            log_info "Keeping .env file"
        fi
    fi
}

# =============================================================================
# Main Cleanup Flow
# =============================================================================

main() {
    log_header "LLMitM Bug Bounty Hunter - Cleanup"
    echo ""

    if [ "$FORCE_MODE" = false ]; then
        log_warn "This will remove:"
        echo "  - All running containers (llmitm-agent, llmitm-firewall, juice-shop)"
        echo "  - Built Docker images"
        echo "  - Docker networks (atomic_internal, atomic_external, etc.)"
        if [ "$KEEP_VOLUMES" = false ]; then
            echo "  - Data volumes (llmitm-captures, llmitm-certs)"
        fi
        echo "  - .env file (optional prompt)"
        echo ""

        if ! confirm "Continue with cleanup?"; then
            log_info "Cleanup cancelled"
            exit 0
        fi
    fi

    echo ""
    cleanup_containers
    echo ""

    cleanup_images
    echo ""

    cleanup_networks
    echo ""

    cleanup_volumes
    echo ""

    cleanup_env
    echo ""

    log_header "Cleanup Complete"
    log_info "You can now run './launch.sh' to start fresh"
}

# =============================================================================
# Entry Point
# =============================================================================

main
