# Implementation Plan: Devcontainer for mitmproxy-ai-tool

## Overview

Transform mitmproxy-ai-tool into an out-of-the-box Claude Code devcontainer with IP-restricted network access for authorized bug bounty testing.

---

## Final Directory Structure

```
mitmproxy-ai-tool/
├── .devcontainer/                    # NEW - Container configuration
│   ├── devcontainer.json             # VS Code devcontainer config
│   ├── Dockerfile                    # Container image definition
│   ├── init-firewall.sh              # Network isolation setup
│   └── targets.conf.example          # Example target whitelist
├── .claude/
│   ├── agents/
│   │   └── llmitm.md                 # Existing subagent
│   ├── memory/
│   │   ├── session.md                # Existing
│   │   ├── hypotheses.md             # Existing
│   │   ├── findings.md               # Existing
│   │   └── implementationPlan.md     # This file
│   └── settings.json                 # NEW - Claude Code container settings
├── captures/                         # Existing (volume-mounted)
├── certs/                            # NEW - mitmproxy CA certificates
├── docs/                             # Existing
├── CLAUDE.md                         # Existing playbook
├── README.md                         # UPDATE - Add container instructions
├── requirements.txt                  # NEW - Python dependencies
├── mitmdump-cheatsheet.md            # Existing
├── Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md  # Existing
├── llmitm-juiceshop.sh               # Existing
├── .gitignore                        # UPDATE - Add new ignores
└── .env.example                      # NEW - Environment template
```

---

## Phase 1: Core Container Files

### 1.1 Dockerfile

**Path:** `.devcontainer/Dockerfile`

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Metadata
LABEL maintainer="llmitm"
LABEL description="Claude Code Bug Bounty Hunter with mitmproxy"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Node.js prerequisites
    curl \
    ca-certificates \
    gnupg \
    # Network tools (firewall)
    iptables \
    iproute2 \
    netcat-openbsd \
    dnsutils \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Development tools
    git \
    zsh \
    fzf \
    jq \
    vim \
    nano \
    htop \
    # Clean up
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install mitmproxy via pip (latest stable)
RUN pip3 install --no-cache-dir mitmproxy

# Create directories
RUN mkdir -p /home/vscode/captures \
             /home/vscode/certs \
             /home/vscode/.claude

# Copy firewall script
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# Set shell to zsh
RUN chsh -s /bin/zsh vscode

# Working directory
WORKDIR /workspace

# Default command
CMD ["sleep", "infinity"]
```

**Key decisions:**
- Base image: `mcr.microsoft.com/devcontainers/base:ubuntu-22.04` (official, maintained)
- Node.js 20 LTS for Claude Code CLI
- mitmproxy via pip (simpler than apt, more up-to-date)
- All network tools for firewall management

---

### 1.2 devcontainer.json

**Path:** `.devcontainer/devcontainer.json`

```json
{
  "name": "LLMitM Bug Bounty Hunter",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "."
  },

  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW"
  ],

  "containerEnv": {
    "CLAUDE_API_KEY": "${localEnv:CLAUDE_API_KEY}",
    "TARGET_IPS": "${localEnv:TARGET_IPS}",
    "TARGET_DOMAINS": "${localEnv:TARGET_DOMAINS}",
    "MITMPROXY_PORT": "8080"
  },

  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind",
    "source=llmitm-captures,target=/workspace/captures,type=volume",
    "source=llmitm-certs,target=/workspace/certs,type=volume"
  ],

  "forwardPorts": [8080],
  "portsAttributes": {
    "8080": {
      "label": "mitmproxy",
      "onAutoForward": "notify"
    }
  },

  "postCreateCommand": "bash .devcontainer/init-firewall.sh",
  "postStartCommand": "mitmdump --version && claude --version",

  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "charliermarsh.ruff",
        "redhat.vscode-yaml"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "python.defaultInterpreterPath": "/usr/bin/python3"
      }
    }
  },

  "remoteUser": "vscode"
}
```

**Key decisions:**
- `NET_ADMIN` + `NET_RAW` capabilities for iptables
- Named volumes for captures and certs (persist across rebuilds)
- Bind mount for source code (editable)
- Port 8080 forwarded for mitmproxy
- Environment variables passed from host

---

### 1.3 init-firewall.sh

**Path:** `.devcontainer/init-firewall.sh`

```bash
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
# OPTIONAL: Development Infrastructure
# ============================================
# Uncomment if needed for package installation
# log_info "Whitelisting npm registry..."
# iptables -A OUTPUT -d registry.npmjs.org -p tcp --dport 443 -j ACCEPT
# iptables -A OUTPUT -d pypi.org -p tcp --dport 443 -j ACCEPT

# log_info "Whitelisting GitHub..."
# iptables -A OUTPUT -d github.com -p tcp --dport 443 -j ACCEPT
# iptables -A OUTPUT -d api.github.com -p tcp --dport 443 -j ACCEPT

# ============================================
# BUG BOUNTY: Target Whitelist
# ============================================

# Read targets from environment variable (comma-separated)
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

        # Check if it's an IP or domain
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
```

**Key decisions:**
- Default-deny outbound (only whitelisted traffic allowed)
- Three ways to specify targets: `TARGET_IPS` env, `TARGET_DOMAINS` env, `targets.conf` file
- Domain resolution at startup (IPs cached in iptables)
- Logging of dropped packets for debugging
- Connectivity test on startup

---

### 1.4 targets.conf.example

**Path:** `.devcontainer/targets.conf.example`

```conf
# LLMitM Target Whitelist
# =======================
# Add authorized bug bounty targets here.
# One target per line. Supports:
#   - IP addresses: 192.168.1.100
#   - CIDR ranges: 10.0.0.0/24
#   - Domains: api.target.com (resolved at container start)
#
# Lines starting with # are comments.
# Copy to targets.conf and edit for your engagement.

# Example targets (uncomment to use):
# 192.168.1.100
# 10.0.0.0/24
# api.target.com
# *.target.com
```

---

## Phase 2: Supporting Files

### 2.1 requirements.txt

**Path:** `requirements.txt`

```
mitmproxy>=10.0.0
```

**Note:** Minimal - mitmproxy handles its own dependencies. Add addon requirements as needed.

---

### 2.2 .env.example

**Path:** `.env.example`

```bash
# Claude Code API Key (required)
CLAUDE_API_KEY=sk-ant-...

# Bug Bounty Target Configuration
# Comma-separated IPs to whitelist
TARGET_IPS=192.168.1.100,10.0.0.50

# Comma-separated domains to whitelist (resolved at container start)
TARGET_DOMAINS=api.target.com,app.target.com

# Mitmproxy port (default: 8080)
MITMPROXY_PORT=8080
```

---

### 2.3 .gitignore Updates

**Path:** `.gitignore` (append)

```gitignore
# Existing
repos/mitmproxy

# New additions
.env
.devcontainer/targets.conf
captures/*.mitm
certs/
*.pyc
__pycache__/
.venv/
```

---

### 2.4 Claude Code Settings

**Path:** `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(mitmdump:*)",
      "Bash(iptables:*)",
      "Bash(curl:*)",
      "Bash(dig:*)",
      "Read",
      "Write",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf /)*",
      "Bash(shutdown)*"
    ]
  }
}
```

---

## Phase 3: Documentation Updates

### 3.1 README.md Section to Add

```markdown
## Running in Container (Recommended)

### Prerequisites
- Docker Desktop or Docker Engine
- VS Code with Remote - Containers extension
- Claude API key

### Quick Start

1. **Clone and configure:**
   ```bash
   git clone https://github.com/cybersharkvin/llmitm.git
   cd llmitm
   cp .env.example .env
   # Edit .env with your CLAUDE_API_KEY and target IPs
   ```

2. **Configure targets:**
   ```bash
   cp .devcontainer/targets.conf.example .devcontainer/targets.conf
   # Edit targets.conf with authorized bug bounty targets
   ```

3. **Open in VS Code:**
   ```bash
   code .
   ```
   When prompted, click "Reopen in Container"

4. **Verify setup:**
   ```bash
   # Check firewall rules
   iptables -L OUTPUT -v -n

   # Test Claude API
   curl -I https://api.anthropic.com

   # Test mitmproxy
   mitmdump --version
   ```

5. **Start hunting:**
   ```bash
   claude
   # Or use the subagent directly
   ```

### Network Isolation

The container implements **default-deny networking**:
- Only whitelisted IPs/domains can be reached
- Claude API is always allowed
- All other outbound traffic is blocked and logged

View blocked connections:
```bash
dmesg | grep LLMITM_DROPPED
```

### Configuring Targets

Three ways to whitelist targets:

1. **Environment variables** (in .env):
   ```bash
   TARGET_IPS=192.168.1.100,10.0.0.50
   TARGET_DOMAINS=api.target.com
   ```

2. **targets.conf file**:
   ```
   192.168.1.100
   api.target.com
   10.0.0.0/24
   ```

3. **Runtime** (requires NET_ADMIN):
   ```bash
   sudo iptables -A OUTPUT -d new-target.com -j ACCEPT
   ```
```

---

## Phase 4: Implementation Order

### Step 1: Create directory structure
```bash
mkdir -p .devcontainer certs
```

### Step 2: Create core files (in order)
1. `.devcontainer/Dockerfile`
2. `.devcontainer/devcontainer.json`
3. `.devcontainer/init-firewall.sh`
4. `.devcontainer/targets.conf.example`

### Step 3: Create supporting files
5. `requirements.txt`
6. `.env.example`
7. `.claude/settings.json`

### Step 4: Update existing files
8. `.gitignore` - append new entries
9. `README.md` - add container section

### Step 5: Test
10. Build container locally
11. Verify firewall rules
12. Test Claude API connectivity
13. Test mitmproxy functionality
14. Test target whitelisting

### Step 6: Git tracking
15. Stage all new files
16. Commit with descriptive message

---

## Verification Checklist

### Container Build
- [ ] Dockerfile builds without errors
- [ ] All dependencies installed (node, python, mitmproxy, claude)
- [ ] Container starts successfully

### Network Isolation
- [ ] Default outbound policy is DROP
- [ ] Claude API (api.anthropic.com) is reachable
- [ ] Non-whitelisted hosts are blocked
- [ ] Dropped packets are logged
- [ ] TARGET_IPS environment variable works
- [ ] TARGET_DOMAINS environment variable works
- [ ] targets.conf file is read correctly

### Functionality
- [ ] `mitmdump --version` works
- [ ] `claude --version` works
- [ ] Captures persist in volume across container rebuilds
- [ ] Certs persist in volume across container rebuilds
- [ ] Port 8080 is accessible from host

### Agent Operation
- [ ] Claude Code can execute mitmdump commands
- [ ] Agent memory files are accessible
- [ ] CLAUDE.md playbook is loaded

---

## Security Considerations

1. **API Key Protection**: Never commit `.env` - use `.env.example` as template
2. **Target Scope**: Firewall physically prevents scope creep
3. **Evidence Preservation**: Named volumes persist findings
4. **Audit Trail**: Dropped packets logged for review
5. **Least Privilege**: Container runs as `vscode` user, not root

---

## Future Enhancements (Out of Scope)

- GitHub Actions CI/CD for container builds
- Multi-architecture support (arm64)
- Pre-built container image on Docker Hub
- Integration with other security tools (nuclei, httpx)
- Automated target scope validation from HackerOne/Bugcrowd APIs
