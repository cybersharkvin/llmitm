# LLMitM - LLM-in-the-Middle Proxy

An autonomous bug bounty hunting agent that operates mitmdump CLI to capture, analyze, mutate, and replay HTTP/HTTPS traffic for security testing.

## Overview

LLMitM transforms mitmproxy's CLI (`mitmdump`) into an LLM-operated security testing tool. The agent works autonomously through a capture→analyze→mutate→replay→observe workflow, hunting for vulnerabilities like IDOR, authentication bypass, privilege escalation, and sensitive data exposure.

**Key constraint**: CLI-only operation. The agent uses `mitmdump` exclusively—never `mitmproxy` (interactive) or `mitmweb` (GUI).

## Features

- **Traffic Capture**: Live interception with domain/method/content filtering
- **Offline Analysis**: Read and filter saved `.mitm` files
- **Request Mutation**: Modify headers (`-H`) and bodies (`-B`) for security testing
- **Client Replay**: Re-send modified requests and observe responses
- **Vulnerability Detection**: IDOR, auth bypass, privilege escalation, data exposure
- **Evidence Collection**: Reproducible commands for bug bounty reports
- **Memory System**: Persistent session state, hypotheses tracking, findings documentation
- **Network Isolation**: Two-container architecture prevents scope creep

## Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Docker Compose                                                             │
│                                                                            │
│  ┌─────────────────┐        ┌───────────────────────────────────────────┐  │
│  │ firewall        │        │ llmitm                                    │  │
│  │ (squid proxy)   │◄──────►│ (claude + mitmproxy)                      │  │
│  │                 │        │                                           │  │
│  │ ✓ Internet      │        │ ✗ No internet access                     │  │
│  │ ✓ Allowlist     │        │ ✗ No NET_ADMIN capability                │  │
│  │ ✓ NET_ADMIN     │        │ ✓ Full agent autonomy inside             │  │
│  └────────┬────────┘        └───────────────────────────────────────────┘  │
│           │                             │                                  │
│      external                      internal                                │
│      network                       network (isolated)                      │
└───────────┼─────────────────────────────┼──────────────────────────────────┘
            │                             │
            ▼                             ▼
        Internet                    No route out
    (Claude API + targets)      (all traffic via proxy)
```

**Security Model:**
- Agent container has **no direct internet access**
- Agent container has **no capability to modify firewall rules**
- All egress flows through firewall sidecar with allowlist
- Agent config (`.claude/`) is mounted **read-only**
- Agent **cannot see** `docker-compose.yml` or `.devcontainer/` (infrastructure files)

---

## Quick Start

### Option 1: VS Code Devcontainer (Recommended)

1. **Clone & Open** → Clone repo and open in VS Code
2. **Configure** → Edit `.env` with your API key and target:
   ```bash
   cp .env.example .env
   # Set CLAUDE_API_KEY=sk-ant-...
   # Set TARGET_DOMAINS=<target-ip-or-domain>
   ```
3. **Container** → Click "Reopen in Container" when prompted
4. **Launch** → Open terminal and run:
   ```bash
   claude --dangerously-skip-permissions --agent llmitm
   ```
5. **Hunt** → Type a prompt like "Test the target for IDOR vulnerabilities"

The pentest atomizer automatically breaks down your request into a CAMRO workflow, and the llmitm agent executes it autonomously—updating memory files as it captures, analyzes, mutates, replays, and observes.

### Option 2: Docker Compose (Standalone)

```bash
# 1. Clone repository
git clone <repo-url> llmitm
cd llmitm

# 2. Configure environment
cp .env.example .env
# Edit .env with CLAUDE_API_KEY and TARGET_DOMAINS

# 3. Start containers
docker-compose up -d

# 4. Enter agent container and launch
docker-compose exec llmitm bash
claude --dangerously-skip-permissions --agent llmitm
```

### Prerequisites

- Docker Desktop or Docker Engine
- Claude API key (get from https://console.anthropic.com/)
- VS Code + Remote Containers extension (for Option 1)

---

## Configuration

### Target Allowlist

Edit `.env` at repo root to add authorized bug bounty targets:

```bash
# Domains (recommended)
TARGET_DOMAINS=api.target.com,app.target.com

# IPs or CIDRs (for direct IP access)
TARGET_IPS=192.168.1.100,10.0.0.0/24
```

**Always allowed:**
- `api.anthropic.com` - Claude API
- `claude.ai` - Claude API
- `statsig.anthropic.com` - Telemetry (can be removed from firewall config)

### Verify Network Isolation

```bash
# From inside llmitm container:

# Should SUCCEED (Claude API)
curl -I https://api.anthropic.com

# Should SUCCEED (if target.com in allowlist)
curl -I https://target.com

# Should FAIL (not in allowlist)
curl -I https://google.com
```

---

## Running Claude

### With Full Permissions (Recommended in Container)

Since network isolation is enforced at the container level, you can run Claude with full permissions:

```bash
claude --dangerously-skip-permissions
```

The agent can do anything inside the container but **cannot escape network restrictions** because:
1. No internet gateway on internal network
2. No NET_ADMIN capability to modify iptables
3. Config directories are read-only
4. Agent cannot see infrastructure files (docker-compose.yml, .devcontainer/)

### Standard Mode

```bash
claude
```

Uses permission rules from `mitmproxy-ai-tool/.claude/settings.json`.

---

## Project Structure

```
llmitm/                              # Repository root (user controls infrastructure)
├── README.md                        # This file
├── docker-compose.yml               # Two-container orchestration
├── .env.example                     # Environment template
├── .env                             # Your config (gitignored)
├── .devcontainer/                   # Container definitions
│   ├── devcontainer.json            # VS Code integration
│   ├── Dockerfile                   # Agent container image
│   └── firewall/
│       ├── Dockerfile               # Firewall sidecar image
│       ├── entrypoint.sh            # Allowlist configuration
│       └── squid.conf               # Proxy configuration
│
└── mitmproxy-ai-tool/               # Agent working directory (/workspace)
    ├── .claude/
    │   ├── agents/
    │   │   └── llmitm.md            # Subagent definition
    │   ├── memory/
    │   │   ├── session.md           # Current target, captures, proxy state
    │   │   ├── hypotheses.md        # Test theories and queue
    │   │   └── findings.md          # Confirmed vulnerabilities
    │   └── settings.json            # Claude Code permissions
    ├── captures/                    # Traffic capture files (volume)
    ├── certs/                       # mitmproxy CA certificates (volume)
    ├── CLAUDE.md                    # Agent playbook
    ├── mitmdump-cheatsheet.md       # CLI command reference
    └── Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md
```

**Security Boundary:**
- `llmitm/` (repo root) = User-controlled infrastructure
- `mitmproxy-ai-tool/` = Agent's visible working directory
- Agent sees `/workspace` which maps to `mitmproxy-ai-tool/` only

---

## Core Workflow (CAMRO)

```
1. CAPTURE  →  mitmdump -w traffic.mitm "~d target.com"
2. ANALYZE  →  mitmdump -nr traffic.mitm --flow-detail 3
3. MUTATE   →  mitmdump -nr traffic.mitm -B "/user_id=1/user_id=2" -w mutated.mitm
4. REPLAY   →  mitmdump -C mutated.mitm --flow-detail 3
5. OBSERVE  →  Analyze response for vulnerability indicators
```

## Filter Reference

| Filter | Matches | Example |
|--------|---------|---------|
| `~d` | Domain | `~d api.target.com` |
| `~u` | URL path | `~u /api/v1/users` |
| `~m` | HTTP method | `~m POST` |
| `~c` | Status code | `~c 401` or `~c "4.."` |
| `~bq` | Request body | `~bq password` |
| `~bs` | Response body | `~bs token` |

**Operators**: `&` (and), `|` (or), `!` (not), `()` (group)

---

## Common Commands

```bash
# Start capture proxy
mitmdump -w traffic.mitm "~d target.com"

# Analyze captured traffic
mitmdump -nr traffic.mitm --flow-detail 3

# Test IDOR by changing user ID
mitmdump -nr traffic.mitm -B "/user_id=123/user_id=456" -w idor-test.mitm
mitmdump -C idor-test.mitm --flow-detail 3

# Inject admin header
mitmdump -C traffic.mitm -H "/~q/X-User-Role/admin" --flow-detail 3

# Find sensitive data in responses
mitmdump -nr traffic.mitm "~bs password|api_key|secret|token" --flow-detail 3
```

---

## Agent Memory System

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `session.md` | Target scope, captured files, proxy status | After every capture/replay |
| `hypotheses.md` | Vulnerability theories, test queue | Before/after each test |
| `findings.md` | Confirmed vulnerabilities with evidence | When confirming vulns |

---

## Vulnerability Focus

| Type | Description | Test Approach |
|------|-------------|---------------|
| **IDOR** | Access other users' resources | Swap user IDs in requests |
| **Auth Bypass** | Skip authentication | Inject admin headers, modify tokens |
| **Privilege Escalation** | Elevate permissions | Change role/permission fields |
| **Data Exposure** | Leak sensitive info | Search responses for tokens/keys |

---

## Viewing Firewall Logs

```bash
# From repo root (not inside container)
docker-compose logs firewall

# Real-time
docker-compose logs -f firewall
```

Squid logs show allowed/denied requests with timestamps.

---

## Troubleshooting

### Agent can't reach Claude API

```bash
# Check firewall is running (from repo root)
docker-compose ps

# Check firewall logs
docker-compose logs firewall

# Test from inside agent container
curl -v https://api.anthropic.com
```

### Agent can't reach target

1. Verify target is in `.env` at repo root:
   ```bash
   grep TARGET .env
   ```

2. Restart firewall to reload config:
   ```bash
   docker-compose restart firewall
   ```

3. Check squid allowlist:
   ```bash
   docker-compose exec firewall cat /etc/squid/allowlist.txt
   ```

---

## Documentation

- **[Agent Playbook](mitmproxy-ai-tool/CLAUDE.md)** - Filters, modifications, workflows
- **[CLI Cheatsheet](mitmproxy-ai-tool/mitmdump-cheatsheet.md)** - Complete mitmdump reference
- **[Penetration Testing Guide](mitmproxy-ai-tool/Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md)** - Advanced techniques

---

## Security Notice

This tool is designed for **authorized security testing only**:
- Bug bounty programs with explicit scope
- Penetration testing with written authorization
- Security research on your own applications
- CTF competitions and training environments

**Never use against systems without permission.**

The two-container architecture prevents accidental scope creep by ensuring the agent can only reach explicitly allowlisted targets. The security boundary prevents the agent from even viewing the infrastructure configuration.

---

## License

See upstream mitmproxy license.
