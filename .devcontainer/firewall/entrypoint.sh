#!/bin/bash
set -e

echo "=========================================="
echo "LLMitM Firewall Sidecar Starting"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[FIREWALL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[FIREWALL]${NC} $1"; }

# =============================================================================
# SQUID ALLOWLIST CONFIGURATION
# =============================================================================

ALLOWLIST_FILE="/etc/squid/allowlist.txt"

log_info "Building allowlist..."

# Start with Claude API (always required)
cat > "$ALLOWLIST_FILE" << 'EOF'
# Claude API - Required for agent operation
.anthropic.com
.claude.ai
# Telemetry (optional - comment out to disable)
.statsig.anthropic.com
.sentry.io
EOF

# Add target domains from environment
if [ -n "$TARGET_DOMAINS" ]; then
    log_info "Adding target domains from environment..."
    IFS=',' read -ra DOMAINS <<< "$TARGET_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            log_info "  + $domain"
            # Add domain and wildcard subdomain
            echo "$domain" >> "$ALLOWLIST_FILE"
            echo ".$domain" >> "$ALLOWLIST_FILE"
        fi
    done
fi

log_info "Allowlist contents:"
cat "$ALLOWLIST_FILE"

# =============================================================================
# IPTABLES CONFIGURATION (for TARGET_IPS direct access)
# =============================================================================

log_info "Configuring iptables..."

# Flush existing rules
iptables -F
iptables -t nat -F

# Default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT for internal network (masquerade outbound)
iptables -t nat -A POSTROUTING -s 172.28.0.0/24 -o eth0 -j MASQUERADE

# Allow forwarding from internal network
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Add TARGET_IPS to direct iptables allowlist (bypasses proxy for raw IP access)
if [ -n "$TARGET_IPS" ]; then
    log_info "Adding target IPs to iptables allowlist..."
    IFS=',' read -ra IPS <<< "$TARGET_IPS"
    for ip in "${IPS[@]}"; do
        ip=$(echo "$ip" | xargs)
        if [ -n "$ip" ]; then
            log_info "  + $ip (direct IP access)"
            iptables -A FORWARD -d "$ip" -j ACCEPT
        fi
    done
fi

log_info "iptables rules:"
iptables -L -v -n

# =============================================================================
# INITIALIZE SQUID CACHE
# =============================================================================

log_info "Initializing Squid cache..."
squid -z 2>/dev/null || true

# =============================================================================
# START SQUID PROXY
# =============================================================================

log_info "Starting Squid proxy on port 3128..."
log_info "Firewall sidecar ready!"
echo "=========================================="

# Run squid in foreground
exec squid -N -d 1
