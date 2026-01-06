#!/bin/bash
set -e

echo "=========================================="
echo "LLMitM Firewall - SNI Proxy"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info() { echo -e "${GREEN}[FIREWALL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[FIREWALL]${NC} $1"; }

# =============================================================================
# IPTABLES CONFIGURATION
# =============================================================================

log_info "Configuring iptables..."

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

# NAT for internal network
iptables -t nat -A POSTROUTING -s 172.28.0.0/24 -o eth0 -j MASQUERADE

# Forward from internal to external
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

# TARGET_IPS direct passthrough (bypass proxy entirely)
if [ -n "$TARGET_IPS" ]; then
    log_info "Adding TARGET_IPS to direct passthrough..."
    IFS=',' read -ra IPS <<< "$TARGET_IPS"
    for ip in "${IPS[@]}"; do
        ip=$(echo "$ip" | xargs)
        if [ -n "$ip" ]; then
            log_info "  + $ip (direct)"
            # Insert BEFORE the REDIRECT rules
            iptables -t nat -I PREROUTING -i eth1 -d "$ip" -j ACCEPT
        fi
    done
fi

# TRANSPARENT PROXY: Redirect HTTP/HTTPS to SNI proxy
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A PREROUTING -i eth1 -p tcp --dport 443 -j REDIRECT --to-port 8443

log_info "iptables configured"

# =============================================================================
# START DNSMASQ
# =============================================================================

log_info "Starting dnsmasq..."
cat > /etc/dnsmasq.conf << 'EOF'
listen-address=172.28.0.2
bind-interfaces
server=8.8.8.8
server=8.8.4.4
no-resolv
EOF

dnsmasq
log_info "dnsmasq started"

# =============================================================================
# START SNI PROXY
# =============================================================================

log_info "Starting SNI proxy..."
log_info "HTTP  -> :8080"
log_info "HTTPS -> :8443"
log_info "Allowlist from TARGET_DOMAINS: ${TARGET_DOMAINS:-<none>}"
echo "=========================================="

cd /etc/proxy
exec python sni_proxy.py
