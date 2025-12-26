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

    # Stop and remove llmitm agent
    if docker ps -a --format '{{.Names}}' | grep -q "^llmitm-agent$"; then
        log_info "Removing container: llmitm-agent"
        docker rm -f llmitm-agent 2>/dev/null || true
        log_success "Removed llmitm-agent"
    fi

    # Stop and remove firewall sidecar
    if docker ps -a --format '{{.Names}}' | grep -q "^llmitm-firewall$"; then
        log_info "Removing container: llmitm-firewall"
        docker rm -f llmitm-firewall 2>/dev/null || true
        log_success "Removed llmitm-firewall"
    fi

    # Stop and remove Juice Shop (if created by launch.sh)
    if docker ps -a --format '{{.Names}}' | grep -q "^juice-shop$"; then
        log_info "Removing container: juice-shop"
        docker rm -f juice-shop 2>/dev/null || true
        log_success "Removed juice-shop"
    fi
}

cleanup_images() {
    log_header "Removing Images"

    # Remove any llmitm-related images (agent, firewall, etc.)
    # Docker-compose may name them with underscore or hyphen depending on context
    for image_pattern in "llmitm_agent" "llmitm-agent" "llmitm_firewall" "llmitm-firewall" "atomic-firewall" "atomic_firewall"; do
        if docker images --format '{{.Repository}}' | grep -q "$image_pattern"; then
            log_info "Removing image: $image_pattern"
            docker rmi -f "$image_pattern" 2>/dev/null || true
        fi
    done
    log_success "Removed all llmitm images"
}

cleanup_networks() {
    log_header "Removing Networks"

    # Remove custom networks
    for network in atomic_internal atomic_external llmitm_internal llmitm_external; do
        if docker network ls --format '{{.Name}}' | grep -q "^${network}$"; then
            log_info "Removing network: $network"
            docker network rm "$network" 2>/dev/null || true
            log_success "Removed network: $network"
        fi
    done
}

cleanup_volumes() {
    log_header "Removing Volumes"

    if [ "$KEEP_VOLUMES" = true ]; then
        log_info "Skipping volume cleanup (--keep-volumes flag set)"
        return 0
    fi

    # Remove data volumes
    for volume in llmitm-captures llmitm-certs; do
        if docker volume ls --format '{{.Name}}' | grep -q "^${volume}$"; then
            log_info "Removing volume: $volume"
            docker volume rm "$volume" 2>/dev/null || true
            log_success "Removed volume: $volume"
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
