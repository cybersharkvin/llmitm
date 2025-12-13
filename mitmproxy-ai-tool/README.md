# LLMITM - LLM-in-the-Middle Proxy

An autonomous bug bounty hunting agent that operates mitmdump CLI to capture, analyze, mutate, and replay HTTP/HTTPS traffic for security testing.

## Overview

LLMITM transforms mitmproxy's CLI (`mitmdump`) into an LLM-operated security testing tool. The agent works autonomously through a capture→analyze→mutate→replay→observe workflow, hunting for vulnerabilities like IDOR, authentication bypass, privilege escalation, and sensitive data exposure.

**Key constraint**: CLI-only operation. The agent uses `mitmdump` exclusively—never `mitmproxy` (interactive) or `mitmweb` (GUI).

## Features

- **Traffic Capture**: Live interception with domain/method/content filtering
- **Offline Analysis**: Read and filter saved `.mitm` files
- **Request Mutation**: Modify headers (`-H`) and bodies (`-B`) for security testing
- **Client Replay**: Re-send modified requests and observe responses
- **Vulnerability Detection**: IDOR, auth bypass, privilege escalation, data exposure
- **Evidence Collection**: Reproducible commands for bug bounty reports
- **Memory System**: Persistent session state, hypotheses tracking, findings documentation

## Running in Container (Recommended)

The easiest way to run LLMITM is in a devcontainer with built-in network isolation.

### Prerequisites

- Docker Desktop or Docker Engine
- VS Code with Remote - Containers extension
- Claude API key

### Quick Start

1. **Clone and configure:**
   ```bash
   git clone https://github.com/cybersharkvin/llmitm.git
   cd llmitm/mitmproxy-ai-tool
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

---

## Manual Installation (Alternative)

If you prefer running outside a container:

### Prerequisites

1. **mitmproxy** (provides `mitmdump`)
   ```bash
   # Create and activate a virtual environment
   python3 -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate

   # Install mitmproxy
   pip install mitmproxy
   ```

2. **Claude Code CLI**
   - Install from: https://claude.ai/code

3. **CA Certificate** (for HTTPS interception)
   - Start mitmdump once, then install `~/.mitmproxy/mitmproxy-ca-cert.pem` in your browser/system

## Quick Start

### Option 1: Juice Shop Demo

Test against OWASP Juice Shop (a vulnerable training app):

```bash
# Terminal 1: Start Juice Shop
docker run --rm -p 127.0.0.1:3000:3000 bkimminich/juice-shop

# Terminal 2: Launch agent
cd mitmproxy-ai-tool
./llmitm-juiceshop.sh
```

### Option 2: Manual Launch

```bash
cd mitmproxy-ai-tool
claude -p "Target: api.example.com. Read @CLAUDE.md and @.claude/memory/, then begin security testing."
```

### Option 3: Analyze Existing Traffic

```bash
cd mitmproxy-ai-tool
claude -p "Analyze traffic.mitm for IDOR vulnerabilities. Read @CLAUDE.md first."
```

## Project Structure

```
mitmproxy-ai-tool/
├── .devcontainer/               # Container configuration
│   ├── devcontainer.json        # VS Code devcontainer config
│   ├── Dockerfile               # Container image definition
│   ├── init-firewall.sh         # Network isolation setup
│   └── targets.conf.example     # Example target whitelist
├── .claude/
│   ├── agents/
│   │   └── llmitm.md            # Subagent definition
│   ├── memory/
│   │   ├── session.md           # Current target, captures, proxy state
│   │   ├── hypotheses.md        # Test theories and queue
│   │   └── findings.md          # Confirmed vulnerabilities
│   └── settings.json            # Claude Code permissions
├── captures/                    # Traffic capture files (volume-mounted)
├── certs/                       # mitmproxy CA certificates
├── docs/
│   └── CLAUDE.md                # Extended documentation navigation
├── repos/
│   └── mitmproxy/               # Upstream mitmproxy source (reference)
├── CLAUDE.md                    # Agent playbook (system prompt)
├── agent-config.json            # Agent configuration
├── llmitm-juiceshop.sh          # Demo launcher for Juice Shop
├── mitmdump-cheatsheet.md       # CLI command reference
├── Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md
│                                # Advanced security techniques
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment variable template
└── .gitignore                   # Git ignore patterns
```

## Agent Memory System

The agent maintains persistent state across sessions through three memory files:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `session.md` | Target scope, captured files, proxy status | After every capture/replay |
| `hypotheses.md` | Vulnerability theories, test queue | Before/after each test |
| `findings.md` | Confirmed vulnerabilities with evidence | When confirming vulns |

## Core Workflow

```
1. CAPTURE  →  mitmdump -w traffic.mitm "~d target.com"
2. ANALYZE  →  mitmdump -nr traffic.mitm --flow-detail 3
3. FILTER   →  mitmdump -nr traffic.mitm "~m POST & ~u /api"
4. MUTATE   →  mitmdump -nr traffic.mitm -B "/user_id=1/user_id=2" -w mutated.mitm
5. REPLAY   →  mitmdump -C mutated.mitm --flow-detail 3
6. OBSERVE  →  Analyze response for vulnerability indicators
7. ITERATE  →  Refine mutations based on findings
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
| `~hq` | Request header | `~hq Authorization` |

**Operators**: `&` (and), `|` (or), `!` (not), `()` (group)

## Common Commands

```bash
# Start capture proxy
mitmdump -w traffic.mitm "~d target.com"

# Analyze captured traffic
mitmdump -nr traffic.mitm --flow-detail 3

# Find authentication endpoints
mitmdump -nr traffic.mitm "~u /auth|/login|/token" --flow-detail 3

# Test IDOR by changing user ID
mitmdump -nr traffic.mitm -B "/user_id=123/user_id=456" -w idor-test.mitm
mitmdump -C idor-test.mitm --flow-detail 3

# Inject admin header
mitmdump -C traffic.mitm -H "/~q/X-User-Role/admin" --flow-detail 3

# Find sensitive data in responses
mitmdump -nr traffic.mitm "~bs password|api_key|secret|token" --flow-detail 3
```

## Vulnerability Focus

| Type | Description | Test Approach |
|------|-------------|---------------|
| **IDOR** | Access other users' resources | Swap user IDs in requests |
| **Auth Bypass** | Skip authentication | Inject admin headers, modify tokens |
| **Privilege Escalation** | Elevate permissions | Change role/permission fields |
| **Data Exposure** | Leak sensitive info | Search responses for tokens/keys |

## Documentation

- **[CLAUDE.md](CLAUDE.md)** - Full agent playbook with filters, modifications, workflows
- **[mitmdump-cheatsheet.md](mitmdump-cheatsheet.md)** - Complete CLI reference
- **[Penetration Testing Guide](Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md)** - Advanced security techniques

### docs/CLAUDE.md - Documentation Index

The **[docs/CLAUDE.md](docs/CLAUDE.md)** file serves as a top-level documentation cross-reference for the agent. When the agent needs detailed information beyond the main playbook (e.g., addon development, Python API details, protocol-specific handling), it consults this index to locate the relevant upstream mitmproxy documentation.

**Purpose:**
- Maps all 49 mitmproxy documentation files by section and topic
- Provides cross-references by concept (filters, replay, certificates, addons)
- Points to section index files for deeper exploration

**When the agent uses it:**
- Building custom Python addons for automated detection
- Researching protocol-specific features (WebSocket, DNS, TCP)
- Understanding mitmproxy internals for advanced modifications
- Creating new cheatsheets or guides

## Example Session

```
User: Target is api.example.com with user auth. Test for IDOR on /api/users/{id}

Agent:
1. Reads playbook and memory files
2. Updates session.md with target scope
3. Starts capture: mitmdump -w session.mitm "~d api.example.com"
4. User browses the app...
5. Stops capture, analyzes traffic
6. Forms hypothesis: "User ID parameter may be vulnerable to IDOR"
7. Mutates request: mitmdump -nr session.mitm -B "/users\/123/users\/456" -w idor.mitm
8. Replays: mitmdump -C idor.mitm --flow-detail 3
9. Observes: 200 OK with different user's data!
10. Documents finding in findings.md with reproduction steps
```

## Security Notice

This tool is designed for **authorized security testing only**:
- Bug bounty programs with explicit scope
- Penetration testing with written authorization
- Security research on your own applications
- CTF competitions and training environments

Never use against systems without permission.

## License

See upstream mitmproxy license in `repos/mitmproxy/LICENSE`.
