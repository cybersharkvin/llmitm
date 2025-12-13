# System Patterns

## Architecture Overview

**Framework**: mitmproxy (mitmdump CLI)
**Architecture Type**: LLM-operated autonomous agent
**Design Philosophy**: CLI-first, evidence-driven security testing with network isolation

## Design Patterns

### CLI-Only Operation Pattern
- **Description**: All traffic interception uses `mitmdump` exclusively - never `mitmproxy` (interactive) or `mitmweb` (GUI)
- **When to Use**: All proxy operations, captures, replays, mutations
- **Example**: `mitmdump -w traffic.mitm "~d target.com"`
- **Rationale**: LLMs operate via bash commands; CLI provides scriptable, reproducible operations

### Capture-Analyze-Mutate-Replay-Observe (CAMRO) Workflow
- **Description**: Five-phase security testing cycle that drives all vulnerability hunting
- **When to Use**: Every security testing session
- **Example**:
  ```
  CAPTURE  →  mitmdump -w session.mitm "~d target.com"
  ANALYZE  →  mitmdump -nr session.mitm --flow-detail 3
  MUTATE   →  mitmdump -nr session.mitm -B "/user_id=1/user_id=2" -w test.mitm
  REPLAY   →  mitmdump -C test.mitm --flow-detail 3
  OBSERVE  →  Analyze response for vulnerability indicators
  ```
- **Rationale**: Systematic approach ensures complete coverage and reproducibility

### Agent Memory Pattern
- **Description**: Persistent state across sessions via markdown files
- **When to Use**: Session continuity, hypothesis tracking, finding documentation
- **Files**:
  - `session.md` - Target scope, capture files, proxy state
  - `hypotheses.md` - Theories to test, attack surface notes
  - `findings.md` - Confirmed vulnerabilities with evidence
- **Rationale**: LLM context doesn't persist; memory files provide continuity

### Default-Deny Network Isolation
- **Description**: iptables blocks all outbound except whitelisted targets
- **When to Use**: Container startup (postCreateCommand)
- **Example**: Only Claude API + configured bug bounty targets reachable
- **Rationale**: Prevents accidental scope creep; enforces authorization boundaries

## Component Structure

### mitmproxy-ai-tool
```
mitmproxy-ai-tool/
├── .devcontainer/           # Container configuration
│   ├── Dockerfile           # Ubuntu 22.04 + Node + Python + mitmproxy
│   ├── devcontainer.json    # VS Code container config
│   ├── init-firewall.sh     # Network isolation setup
│   └── targets.conf.example # Target whitelist template
├── .claude/
│   ├── agents/
│   │   └── llmitm.md        # Subagent system prompt
│   ├── memory/
│   │   ├── session.md       # Runtime state
│   │   ├── hypotheses.md    # Test theories
│   │   └── findings.md      # Confirmed vulns
│   └── settings.json        # Tool permissions
├── captures/                # Traffic files (volume-mounted)
├── certs/                   # CA certificates (volume-mounted)
├── docs/                    # Extended documentation
├── CLAUDE.md                # Agent playbook
└── mitmdump-cheatsheet.md   # CLI reference
```

## Data Flow

### Security Testing Flow
1. **Target Configuration** - Set authorized scope via env vars or targets.conf
2. **Firewall Initialization** - init-firewall.sh applies iptables rules
3. **Traffic Capture** - mitmdump writes flows to .mitm files
4. **Analysis** - Agent reads flows, identifies interesting endpoints
5. **Hypothesis Formation** - Agent documents theories in hypotheses.md
6. **Mutation Testing** - Agent modifies requests with -H and -B flags
7. **Replay & Observe** - Agent replays modified requests, checks responses
8. **Documentation** - Confirmed vulns go to findings.md with evidence

### Target Whitelist Flow
1. Environment variables (`TARGET_IPS`, `TARGET_DOMAINS`)
2. targets.conf file (IP/CIDR/domain per line)
3. Runtime iptables commands (requires NET_ADMIN)

## Naming Conventions

### Files
- **Traffic captures**: `{purpose}.mitm` (e.g., `session.mitm`, `idor-test.mitm`)
- **Evidence files**: `evidence-{vuln-id}.mitm` (e.g., `evidence-vuln-001.mitm`)
- **Documentation**: `kebab-case.md`

### Mitmdump Filters
- **Domain**: `~d api.target.com`
- **Path**: `~u /api/v1/users`
- **Method**: `~m POST`
- **Status**: `~c 401` or `~c "4.."`
- **Request body**: `~bq password`
- **Response body**: `~bs token`
- **Combine**: `&` (and), `|` (or), `!` (not), `()` (group)

### Modification Syntax
- **Headers**: `-H "/~q/Header-Name/value"` (request) or `-H "/~s/Header-Name/value"` (response)
- **Body**: `-B "/~q/search/replace"` (request body modification)

## Error Handling Patterns

### Network Isolation Failures
```bash
# Check dropped packets
dmesg | grep LLMITM_DROPPED

# View current rules
iptables -L OUTPUT -v -n

# Add target at runtime (if NET_ADMIN)
sudo iptables -A OUTPUT -d new-target.com -j ACCEPT
```

### Firewall Debug
- All dropped packets logged with prefix `LLMITM_DROPPED:`
- DNS (port 53) always allowed for domain resolution
- Claude API always whitelisted for agent operation

## State Management

### Session State (session.md)
- **Target**: Current domain/scope under test
- **Captures**: List of .mitm files with descriptions
- **Proxy Status**: Running/stopped, port, mode

### Hypothesis State (hypotheses.md)
- **Pending**: Theories awaiting test
- **Testing**: Currently being validated
- **Confirmed**: Moved to findings.md
- **Disproved**: Documented with reasoning

### Findings State (findings.md)
- **Vulnerability Reports**: Type, severity, endpoint, reproduction steps
- **Sensitive Data Log**: Tokens, keys, credentials discovered

---

**Update Frequency**: After establishing new patterns or making architectural decisions
