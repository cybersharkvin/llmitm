# Technical Context

## Tech Stack

**Framework**: mitmproxy (mitmdump CLI)
**Runtime**: Python 3 (system), Node.js 20 LTS
**Language**: Python (addons), Bash (CLI operations)
**Container**: Ubuntu 22.04 (devcontainer)
**Build Tool**: Docker + VS Code devcontainers
**Package Manager**: pip (Python), npm (Node.js/Claude Code)

## Dependencies

### Core Proxy
- **mitmproxy** (>=10.0.0): Traffic interception, capture, replay, mutation

### Runtime
- **Node.js** (20 LTS): Required for Claude Code CLI
- **Python 3**: Required for mitmproxy

### Claude Code
- **@anthropic-ai/claude-code**: Global npm package for LLM agent operation

### Network Tools
- **iptables**: Firewall for default-deny network isolation
- **iproute2**: Network interface management
- **dnsutils**: Domain resolution (dig command)
- **netcat-openbsd**: Network debugging
- **curl**: API connectivity testing

### Development Tools
- **git**: Version control
- **zsh**: Default shell
- **fzf**: Fuzzy finder
- **jq**: JSON processing
- **vim/nano**: Text editors

## Development Setup

### Prerequisites
- Docker Desktop or Docker Engine
- VS Code with Remote - Containers extension
- Claude API key

### Container Build (Automatic)
```bash
# VS Code handles this automatically when opening in container
# Manual build if needed:
docker build -t llmitm .devcontainer/
```

### Quick Start
```bash
cd mitmproxy-ai-tool
cp .env.example .env
# Edit .env with CLAUDE_API_KEY and target IPs
code .
# Click "Reopen in Container" when prompted
```

### Manual Installation (No Container)
```bash
# Python environment
python3 -m venv .venv
source .venv/bin/activate
pip install mitmproxy

# Claude Code CLI
npm install -g @anthropic-ai/claude-code
```

### Verify Setup
```bash
mitmdump --version          # Check mitmproxy
claude --version            # Check Claude Code
iptables -L OUTPUT -v -n    # Check firewall rules
```

## Technical Constraints

### CLI-Only Operation
- **Constraint**: Must use `mitmdump` only - never `mitmproxy` or `mitmweb`
- **Reason**: LLM operates via bash; GUI tools not scriptable

### Network Isolation
- **Constraint**: Default-deny outbound; only whitelisted targets reachable
- **Reason**: Prevents accidental scope creep in bug bounty testing
- **Required**: NET_ADMIN and NET_RAW capabilities

### Container Capabilities
- **NET_ADMIN**: Required for iptables firewall management
- **NET_RAW**: Required for raw packet access

## Configuration

### Environment Variables
**Required**:
- `CLAUDE_API_KEY`: Anthropic API key for Claude Code

**Optional**:
- `TARGET_IPS`: Comma-separated IPs to whitelist (e.g., `192.168.1.100,10.0.0.50`)
- `TARGET_DOMAINS`: Comma-separated domains to whitelist (e.g., `api.target.com`)
- `MITMPROXY_PORT`: Proxy listen port (default: 8080)

### targets.conf
```
# One target per line
# IPs, CIDRs, or domains
192.168.1.100
10.0.0.0/24
api.target.com
```

### devcontainer.json
- **runArgs**: `--cap-add=NET_ADMIN`, `--cap-add=NET_RAW`
- **mounts**: Workspace bind mount, named volumes for captures/certs
- **forwardPorts**: 8080 (mitmproxy)
- **postCreateCommand**: `bash .devcontainer/init-firewall.sh`
- **postStartCommand**: Version checks for mitmproxy and claude

### VS Code Extensions (Container)
- **ms-python.python**: Python language support
- **ms-python.vscode-pylance**: Python type checking
- **charliermarsh.ruff**: Python linting
- **redhat.vscode-yaml**: YAML support

## Known Technical Issues

### Docker Permissions
- **Issue**: Container build requires Docker daemon access
- **Status**: Expected behavior
- **Workaround**: User must be in docker group or use sudo

### Firewall Script Requires sudo
- **Issue**: postCreateCommand runs as vscode user, but iptables needs root
- **Status**: Fixed (2025-12-13)
- **Solution**: `devcontainer.json` uses `sudo bash .devcontainer/init-firewall.sh`

### Domain Resolution in Firewall
- **Issue**: Domains resolved at container start; IP changes not tracked
- **Status**: Known limitation
- **Workaround**: Re-run init-firewall.sh or add IPs at runtime

## Performance Characteristics

### Traffic Capture
- **File Format**: .mitm binary format (mitmproxy native)
- **Storage**: Named Docker volume persists across rebuilds
- **Memory**: Flows loaded into memory for analysis

### Network Latency
- **Proxy Overhead**: Minimal for MITM interception
- **DNS**: Required for domain resolution (port 53 allowed)

## Platform Support

### Container (Recommended)
- **Tested**: Docker Desktop (macOS, Windows), Docker Engine (Linux)
- **Notes**: VS Code devcontainer extension required

### Manual Installation
- **Tested**: Ubuntu 22.04, Debian 12, macOS
- **Notes**: Firewall rules require Linux (iptables)

## Context Management (Claude Code Specific)

### Memory Files (mitmproxy-ai-tool)
Agent-specific memory in `mitmproxy-ai-tool/.claude/memory/`:
- `session.md` - Current target, captures, proxy state
- `hypotheses.md` - Vulnerability theories
- `findings.md` - Confirmed vulnerabilities

### Memory Files (ATOMIC Development)
Development context in `.claude/memory/`:
- `activeContext.md` - Current work state
- `projectBrief.md` - Project goals and scope
- `systemPatterns.md` - Design patterns and architecture
- `techContext.md` - This file (tech stack and constraints)
- `projectProgress.md` - Implementation status
- `tags.md` - Auto-generated code structure

### Tool Permissions (.claude/settings.json)
```json
{
  "permissions": {
    "allow": [
      "mitmdump *",
      "iptables *",
      "dig *",
      "curl *",
      "netcat *"
    ]
  }
}
```

---

**Update Frequency**: After adding dependencies or changing configuration
