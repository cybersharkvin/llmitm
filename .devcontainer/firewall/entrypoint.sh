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
            # Skip IP addresses - they're handled by iptables, not squid dstdomain
            if [[ ! "$domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                log_info "  + $domain (domain)"
                # Add domain and wildcard subdomain
                echo "$domain" >> "$ALLOWLIST_FILE"
                echo ".$domain" >> "$ALLOWLIST_FILE"
            else
                log_info "  + $domain (IP - handled by iptables)"
            fi
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

# =============================================================================
# TRANSPARENT PROXY INTERCEPTION
# =============================================================================
# Redirect HTTP (80) and HTTPS (443) from agent container to squid
# This enables transparent proxying - agent doesn't need to know about proxy

log_info "Configuring transparent proxy interception..."

# Redirect HTTP traffic to squid
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j REDIRECT --to-port 3128
log_info "  + HTTP (port 80) → squid:3128"

# Redirect HTTPS traffic to squid
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 443 -j REDIRECT --to-port 3128
log_info "  + HTTPS (port 443) → squid:3128"

log_info "Transparent proxy interception configured"

log_info "iptables rules:"
iptables -L -v -n

# =============================================================================
# START DNSMASQ (DNS forwarding for agent container)
# =============================================================================

log_info "Starting dnsmasq DNS forwarder..."

# Configure dnsmasq to forward DNS queries
cat > /etc/dnsmasq.conf << 'EOF'
# Listen on internal interface for agent container
listen-address=172.28.0.2
bind-interfaces
# Forward to Google DNS
server=8.8.8.8
server=8.8.4.4
# Don't read /etc/resolv.conf
no-resolv
# Log queries for debugging
log-queries
log-facility=/dev/stdout
EOF

# Start dnsmasq in background
dnsmasq

log_info "dnsmasq started on 172.28.0.2:53"

# =============================================================================
# INITIALIZE SQUID CACHE
# =============================================================================

log_info "Initializing Squid cache..."
# Kill any existing squid processes
pkill -f squid || true
sleep 1
# Clean up any stale PID file
rm -f /var/run/squid.pid /var/run/squid.pid.*
# Initialize Squid cache without starting it
squid -z -f /etc/squid/squid.conf 2>/dev/null || true
sleep 1

# =============================================================================
# START SQUID PROXY
# =============================================================================

log_info "Starting Squid proxy on port 3128..."
log_info "Firewall sidecar ready!"
echo "=========================================="

# Run squid in foreground
exec squid -N -d 1
