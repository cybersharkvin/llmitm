#!/bin/bash
set -e

echo "=========================================="
echo "LLMitM Firewall Initialization"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running with sufficient privileges
if ! iptables -L > /dev/null 2>&1; then
    log_error "Cannot access iptables. Ensure container has NET_ADMIN capability."
    exit 1
fi

# Flush existing rules
log_info "Flushing existing firewall rules..."
iptables -F OUTPUT
iptables -F INPUT
iptables -F FORWARD

# Default policies
log_info "Setting default-deny outbound policy..."
iptables -P INPUT ACCEPT
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback (localhost)
log_info "Allowing localhost traffic..."
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (required for domain resolution)
log_info "Allowing DNS (UDP/TCP 53)..."
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# ============================================
# REQUIRED: Claude API Access
# ============================================
log_info "Whitelisting Claude API endpoints..."
iptables -A OUTPUT -d api.anthropic.com -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d claude.ai -p tcp --dport 443 -j ACCEPT

# Optional: Telemetry (comment out to disable)
iptables -A OUTPUT -d statsig.anthropic.com -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d sentry.io -p tcp --dport 443 -j ACCEPT

# ============================================
# BUG BOUNTY: Target Whitelist
# ============================================

# Read targets from environment variable (comma-separated IPs)
if [ -n "$TARGET_IPS" ]; then
    log_info "Whitelisting target IPs from environment..."
    IFS=',' read -ra IPS <<< "$TARGET_IPS"
    for ip in "${IPS[@]}"; do
        ip=$(echo "$ip" | xargs)  # Trim whitespace
        if [ -n "$ip" ]; then
            log_info "  + $ip"
            iptables -A OUTPUT -d "$ip" -j ACCEPT
        fi
    done
fi

# Read target domains from environment variable (comma-separated)
if [ -n "$TARGET_DOMAINS" ]; then
    log_info "Whitelisting target domains from environment..."
    IFS=',' read -ra DOMAINS <<< "$TARGET_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs)  # Trim whitespace
        if [ -n "$domain" ]; then
            log_info "  + $domain"
            # Resolve domain to IPs and add rules
            resolved_ips=$(dig +short "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
            if [ -n "$resolved_ips" ]; then
                for resolved_ip in $resolved_ips; do
                    log_info "    -> $resolved_ip"
                    iptables -A OUTPUT -d "$resolved_ip" -j ACCEPT
                done
            else
                log_warn "    Could not resolve $domain"
            fi
        fi
    done
fi

# Read from targets.conf if it exists
TARGETS_CONF="/workspace/.devcontainer/targets.conf"
if [ -f "$TARGETS_CONF" ]; then
    log_info "Reading targets from $TARGETS_CONF..."
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        target=$(echo "$line" | xargs)
        log_info "  + $target"

        # Check if it's an IP or CIDR
        if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(/[0-9]+)?$ ]]; then
            # It's an IP or CIDR
            iptables -A OUTPUT -d "$target" -j ACCEPT
        else
            # It's a domain - resolve it
            resolved_ips=$(dig +short "$target" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || true)
            if [ -n "$resolved_ips" ]; then
                for resolved_ip in $resolved_ips; do
                    log_info "    -> $resolved_ip"
                    iptables -A OUTPUT -d "$resolved_ip" -j ACCEPT
                done
            else
                log_warn "    Could not resolve $target"
            fi
        fi
    done < "$TARGETS_CONF"
fi

# ============================================
# Logging and Final Drop
# ============================================
log_info "Enabling dropped packet logging..."
iptables -A OUTPUT -j LOG --log-prefix "LLMITM_DROPPED: " --log-level 4

# Final drop rule
iptables -A OUTPUT -j DROP

# ============================================
# Verification
# ============================================
echo ""
log_info "Firewall rules loaded:"
echo "=========================================="
iptables -L OUTPUT -v -n --line-numbers
echo "=========================================="

# Test Claude API connectivity
echo ""
log_info "Testing Claude API connectivity..."
if curl -s --connect-timeout 5 https://api.anthropic.com > /dev/null 2>&1; then
    log_info "Claude API: REACHABLE"
else
    log_warn "Claude API: UNREACHABLE (check DNS or firewall)"
fi

echo ""
log_info "Firewall initialization complete!"
log_info "Dropped packets logged with prefix: LLMITM_DROPPED"
log_info "View drops: dmesg | grep LLMITM_DROPPED"
