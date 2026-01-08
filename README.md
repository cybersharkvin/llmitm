# LLMitM: Proof-of-Concept for Advanced LLM Architecture in Autonomous Pentesting

An autonomous bug bounty agent that demonstrates how to use LLMs correctly: leveraging terminal-native interfaces, structured memory as attention architecture, assumption-gap methodology, and semantic outsourcing to find vulnerabilities without the token overhead or reasoning degradation of traditional "AI security tools."

Built for [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) and other intentionally vulnerable applications. 

**WARNING** This is NOT your generic AI hypebro tool. This is a methodological proof-of-concept backed by fundamental LLM architecture.

---

## Tl;Dr:

1. Run:
```bash
./launch.sh
```
2. Launch Claude & sign in:
```bash
claude --verbose --permission-mode plan --allow-dangerously-skip-permissions --system-prompt-file ./.claude/agents/llmitm.md
```

3. Paste:
```
@CLAUDE.md we are beginning an initial hunt against the juice shop container. You MUST proceed with initial baselining and subsequent execution of the CAMRO workflow using the mitmdump CLI @docs/CLAUDE.md.

**You MUST update memory files regularly @.claude/memory/**

TARGET="http://172.19.0.3:3000"
```
4. Become 1337 h4ck3r

---

## The Insight

Most AI security tools ask: "How do I connect an LLM to security tools?" This project asks a different question: "How do I structure cognition so the LLM finds what matters?" The answer involves CLI-native interfaces, typed memory as attention architecture, and hunting assumption gaps instead of pattern-matching signatures.

---

## Design Philosophy

This project is built on seven principles that exploit how transformers actually work and how security testing actually happens.

### 1. CLI-Native Architecture
**The Problem**: MCP kills context. Simply loading in tools, their definitions, data types, outputs, etc., immediately bloats the context window *before* your agent actually does anything. This MCP schema overhead consumes 3-4x the context of equivalent CLI commands.

**The Solution**: Use the terminal as the interface. The model already knows CLI from training, meaning all of the abstraction we'd ever need is right there. A single `mitmdump` command costs ~30 tokens. Complex workflows requiring 100+ operations stay tractable because you're not drowning in schema overhead.

### 2. Scaffolded Iterative Task Switching (SITS)
**The Problem**: Multi-turn conversations *WILL* lead to attention dilution. Focused execution requires a focused mind. Your agents are no different.

**The Solution**: Each workflow phase writes conclusions to memory files, then clears conversation context. The next phase reads those files as primed context and starts fresh with a single focused objective.

**Why It Matters**: Past 100k tokens, the amount of context-bleed catastrophically degrades output. Each phase starts fresh (context reset), but memory carries everything that matters forward.

### 3. Typed Epistemic Memory
**The Problem**: Logs are sequential noise. You can't load "what we discovered yesterday" without reading 500 lines of output.

**The Solution**: Three files, three roles:
- **session.md** — what exists (operational state: target, proxy config, captured files)
- **hypotheses.md** — what we believe, including what failed and why (lessons learned)
- **findings.md** — what we've proven (evidence chains with reproducible commands)

Natural-language-driven stratified knowledge. Each file is a context silo that can be loaded independently. **The structure itself is the attention architecture.**

### 4. Semantic Outsourcing
**The Problem**: Asking an LLM to "break down this pentesting task" produces generic advice, not context-aware decomposition.

**The Solution**: A hook intercepts every query before the primary agent sees it. A secondary model reads the request + memory state + project documentation. Far beyond simple planning, it models assumptions and identifies where they diverge. The primary agent receives pre-primed context with fault lines already marked.

**Why It Matters**: Reasoning about *what matters* is separated from *doing it*. The atomizer spends tokens on understanding your specific target. The primary agent spends tokens on execution. Work gets done faster because neither one is wasting energy on trial-and-error.

### 5. Assumption-Gap Methodology
**The Insight**: Vulnerabilities live where mental models diverge.
- Business assumes: "Users should only see their own data"
- Developer assumes: "User IDs in the URL are validated server-side"
- Code does: "Return data for any ID in the database"

The gap is the bug.

**The Implementation**: The atomizer explicitly models three layers of assumptions (business logic, developer intent, implementation reality) and identifies assumption_gaps as outputs. These gaps become priority test targets.

**Why It Works**: Logic flaws that evade signature-based scanners are caught because you're testing the *boundaries of assumptions*, not patterns.

### 6. Capability-Based Isolation
**The Model**: Two containers. Agent has full autonomy inside a sandbox it cannot escape or observe.

**The Reality**:
- Agent container: no NET_ADMIN, no direct internet, no visibility into infrastructure files
- Firewall container: has NET_ADMIN + internet access, controls all egress via SNI proxy
- Agent can run with `--dangerously-skip-permissions` safely

**Why This Matters**: Maximum agency + enforced boundaries. Deployable where other autonomous tools aren't allowed because the architecture *proves* confinement.

### 7. Structured Output Enforcement
**The Problem**: LLM reasoning chains are invisible. You can't audit why it chose endpoint A over endpoint B.

**The Solution**: The atomizer runs with `--json-schema`. It *cannot* produce prose. The schema *is* the methodology.

Required fields in every output:
- `assumptions` — what does the agent believe about the target?
- `assumption_gaps` — where do assumptions diverge?
- `atomic_actions` — numbered steps with dependencies
- `success_criteria` — measurable outcomes per step
- `evidence_requirements` — what constitutes proof?

**Why It Matters**: Consistency across engagements. Machine-parseable. Auditable reasoning chains. You can see exactly what the atomizer prioritized and why.

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────────────┐
│ Docker Compose                                                             │
│                                                                            │
│  ┌─────────────────┐        ┌───────────────────────────────────────────┐  │
│  │ firewall        │        │ llmitm                                    │  │
│  │ (SNI proxy)     │◄──────►│ (claude + mitmproxy)                      │  │
│  │                 │        │                                           │  │
│  │ ✓ Internet      │        │ ✗ No internet access                      │  │
│  │ ✓ Allowlist     │        │ ✗ No NET_ADMIN capability                 │  │
│  │ ✓ NET_ADMIN     │        │ ✓ Full agent autonomy inside              │  │
│  │ ✓ SNI parser    │        │ ✓ Memory files + documentation            │  │
│  └────────┬────────┘        └───────────────────────────────────────────┘  │
│           │                             │                                  │
│      external                      internal                                │
│      network                       network (isolated)                      │
└───────────┼─────────────────────────────┼──────────────────────────────────┘
            │                             │
            ▼                             ▼
        Internet                 Transparent routing
    (Claude API + targets)       (via firewall gateway)
```

**Transparent Proxy**: Agent traffic routes through firewall via injected gateway. Firewall intercepts HTTP (port 80) and HTTPS (port 443). **HTTP**: reads Host header. **HTTPS**: reads SNI from TLS ClientHello—**no TLS decryption**. Agent needs zero proxy configuration.

---

## How It Works: The Hunt Cycle

### Phase 1: Atomic Decomposition

```
Your request → Atomizer reads memory files + docs
             ↓
             Models assumptions + gaps
             ↓
             Outputs structured task.json with:
             - Numbered atomic steps
             - Dependencies (sequential/parallel)
             - Success criteria per step
             - Evidence requirements
             ↓
Primary agent receives pre-primed context
```

The atomizer understands your project state via memory files, using this to prime attention heads toward what matters; resulting in the same context-aware (often better!) reasoning that your primary agent would typically do. This is semantic outsourcing: smaller model does reasoning-about-what-matters, primary model does execution.

### Phase 2: Execution 

```
Agent reads task.json
       ↓
Executes atomic_actions in dependency order
       ↓
For each step:
   - Run mitmdump command
   - Parse output
   - Update memory files (session.md, hypotheses.md, findings.md)
       ↓
Memory updates create feedback loop for next atomization
```

The agent operates CLI-native. Every action is a bash command. Memory files accumulate structured findings, not logs.

### Phase 3: Context Refresh (Scaffolded Iterative Task Switching)

```
Hunt session ends
       ↓
Agent writes conclusions to memory files
       ↓
Conversation context cleared
       ↓
Next phase begins:
   - Reads memory files as primed context
   - Fresh conversation window
   - Focused on next objective (mutate/replay → observe/report)
       ↓
No context degradation. Peak model efficiency by minimizing context bleed.
```

Each phase is a "fresh start" that operates on accumulated project knowledge. This is SITS: context reset, memory-primed, focused objective.

---

## The Five-Phase CAMRO Workflow

```
CAPTURE  → mitmdump -w traffic.mitm "~d target.com"
           (Intercept live traffic)

ANALYZE  → mitmdump -nr traffic.mitm --flow-detail 3
           (Identify endpoints, patterns, authentication)

MUTATE   → mitmdump -nr traffic.mitm -B "/user_id=1/user_id=2" -w test.mitm
           (Modify requests to test hypotheses)

REPLAY   → mitmdump -C test.mitm --flow-detail 3
           (Send mutated requests, observe responses)

OBSERVE  → Analyze responses for vulnerability indicators
           (Confirm hypotheses, document evidence)
```

Each phase writes to memory files. Hypotheses are formulated based on assumption gaps. Tests target specific assumption divergences, not *just* patterns that appear in training data.

---

## Memory System: Stratified Knowledge

| File | Purpose | Role in Architecture |
|------|---------|----------------------|
| **session.md** | Operational state: target, proxy config, captured files, endpoints discovered | What exists; loaded fresh each phase |
| **hypotheses.md** | Beliefs including what failed and why; prioritized by assumption-gap relevance | Lessons learned; failure analysis; theory queue |
| **findings.md** | Proven vulnerabilities with reproducible evidence chains | Auditable proof; bug bounty reports |

Each file is a context silo. The atomizer reads all three and outputs task plans that are tuned to *your specific project state*—**not** generic advice.

---

## Quick Start

### Prerequisites
- Docker Desktop or Docker Engine

---

### One Command Setup

```bash
./launch.sh
```

The script automatically:
1. Detects or creates a Juice Shop container
2. Extracts its IP address
3. Configures `.env` with the target
4. Launches firewall + agent containers
5. Drops you into the agent shell

---

### Launch Claude with Full Autonomy

```bash
claude --verbose \
       --permission-mode plan \
       --allow-dangerously-skip-permissions \
       --system-prompt-file ./.claude/agents/llmitm.md
```

**Flag explanations:**
- `--verbose` — Shows thinking cycles and token expenditure. Watch the atomizer's reasoning.
- `--permission-mode plan` — Starts in plan mode. Atomizer runs first (structured decomposition), then agent executes.
- `--allow-dangerously-skip-permissions` — Full autonomy. Safe here because network isolation is enforced by the container architecture, not permissions.
- `--system-prompt-file ./.claude/agents/llmitm.md` — Direct prompt loading. Avoids the `--agent llmitm` flag which causes context bleed with the atomizer hook.

---

### Your First Hunt

After signing in to Claude Code, paste:

```
@CLAUDE.md we are beginning an initial hunt against the juice shop container. You MUST proceed with initial baselining and subsequent execution of the CAMRO workflow using the mitmdump CLI.

Reference @.claude/memory/ for state, @docs/ for documentation.

You MUST update memory files (session.md, hypotheses.md, findings.md) after each phase.

TARGET="http://172.19.0.3:3000"
```

The agent will:
1. Atomizer decomposes into structured task.json
2. Agent enters plan mode, sees the assumption gaps
3. Agent executes CAMRO phases, updating memory files
4. Memory updates prime the atomizer for the next phase
5. Cycle repeats until hunt complete

---

## Project Structure

```
llmitm/                              # Repository root (infrastructure)
├── README.md                        # Original README
├── README_v2.md                     # This file (design philosophy edition)
├── docker-compose.yml               # Two-container orchestration
├── launch.sh                        # Setup automation
├── cleanup.sh                       # Teardown
├── .env.example                     # Config template
├── .devcontainer/
│   ├── devcontainer.json            # VS Code integration
│   ├── Dockerfile                   # Agent container
│   └── firewall/
│       ├── Dockerfile               # SNI proxy container (Python 3.11)
│       ├── entrypoint.sh            # iptables + proxy startup
│       ├── requirements.txt         # pydantic
│       └── proxy/                   # SNI proxy implementation
│           ├── models.py            # Config models
│           ├── sni_parser.py        # TLS ClientHello parsing
│           └── sni_proxy.py         # Asyncio transparent proxy
│
└── mitmproxy-ai-tool/               # Agent workspace (/workspace in container)
    ├── .claude/
    │   ├── agents/
    │   │   └── llmitm.md            # Agent system prompt
    │   ├── hooks/
    │   │   └── query-atomization.sh # Atomizer hook (runs Haiku)
    │   ├── memory/
    │   │   ├── session.md           # Operational state
    │   │   ├── hypotheses.md        # Test theories + failures
    │   │   └── findings.md          # Proven vulnerabilities
    │   └── settings.json            # Tool permissions
    ├── captures/                    # Traffic files (.mitm)
    ├── certs/                       # mitmproxy CA certificates
    ├── CLAUDE.md                    # Agent playbook (cross-linked)
    ├── mitmdump-cheatsheet.md       # CLI reference
    ├── docs/
    │   ├── CLAUDE.md                # Hub for documentation
    │   └── [deeper guides]
    └── README.md
```

**Boundary**: `llmitm/` (root) = infrastructure. `mitmproxy-ai-tool/` = agent's visible workspace. Agent cannot see docker-compose.yml, .devcontainer/, or .env.

---

## Configuration

### Target Allowlist

Edit `.env` at repo root:

```bash
# Single target
TARGET_DOMAINS=172.17.0.2

# Multiple targets (comma-separated)
TARGET_DOMAINS=api.target.com,app.target.com

# Direct IPs
TARGET_IPS=192.168.1.100,10.0.0.0/24
```

**Always allowed**:
- `api.anthropic.com` — Claude API
- `claude.ai` — Claude API
- `statsig.anthropic.com` — Telemetry

### Verify Network Isolation

```bash
# From inside llmitm container:

# Should SUCCEED (Claude API)
curl -I https://api.anthropic.com

# Should FAIL (not allowlisted)
curl -I https://google.com
```

---

## The Hunt: What Happens Under the Hood

### Execution Flow

**Step 1: You type a prompt**
```
"Test Juice Shop for IDOR vulnerabilities in user endpoints"
```

**Step 2: Atomizer intercepts**
- Reads `session.md` (what we know about the target)
- Reads `hypotheses.md` (what we've already tested)
- Reads `findings.md` (what we've already proven)
- Reads your prompt
- Models assumptions: business logic, developer intent, actual code
- Identifies divergences: "Endpoint /api/users/{id} assumes developer validates ID ownership, but code may not check"
- Outputs `task.json` with atomic steps, dependencies, and evidence requirements

**Step 3: Agent (Claude) receives task.json in plan mode**
- Sees the decomposition
- Reviews assumption gaps (the vulnerability surface)
- Asks clarifying questions if needed
- Executes steps in order

**Step 4: Each step updates memory**
```bash
Step 1: Capture traffic
        → session.md updated with discovered endpoints
Step 2: Analyze responses
        → hypotheses.md populated with testable theories
Step 3: Mutate and replay
        → findings.md updated with confirmed vulnerabilities
```

**Step 5: Conversation reset (SITS)**
- Agent writes summary to memory
- Conversation context cleared
- Memory files carry forward (stratified knowledge)
- Next phase begins with fresh context window, primed by memory

---

## Filter Reference

| Filter | Matches | Example |
|--------|---------|---------|
| `~d` | Domain | `~d api.target.com` |
| `~u` | URL path | `~u /api/v1/users` |
| `~m` | Method | `~m POST` |
| `~c` | Status | `~c 401` or `~c "4.."` |
| `~bq` | Request body | `~bq password` |
| `~bs` | Response body | `~bs token` |
| `~hq` | Request header | `~hq Authorization` |
| `~hs` | Response header | `~hs Set-Cookie` |

**Combine**: `&` (and) `|` (or) `!` (not) `()` (group)

Example: `~d target.com & ~m POST & !~u /logout`

---

## Common Commands

```bash
# Capture
mitmdump -w traffic.mitm "~d target.com"

# Analyze (read offline)
mitmdump -nr traffic.mitm --flow-detail 3

# IDOR test (swap user ID)
mitmdump -nr traffic.mitm -B "/user_id=123/user_id=456" -w idor.mitm
mitmdump -C idor.mitm --flow-detail 3

# Find sensitive data
mitmdump -nr traffic.mitm "~bs password|token|api_key|secret" --flow-detail 3

# Inject header
mitmdump -C traffic.mitm -H "/~q/X-User-Role/admin" --flow-detail 3
```

---

## Vulnerability Focus

| Type | Test Approach | Assumption Gap |
|------|---------------|----------------|
| **IDOR** | Swap user IDs, access other users' resources | Dev assumes ID validation; code doesn't check |
| **Auth Bypass** | Inject headers, modify tokens, remove auth | Dev assumes frontend enforcement; API doesn't verify |
| **Privilege Escalation** | Change role fields, access admin endpoints | Dev assumes roles are immutable; code accepts client input |
| **Data Exposure** | Search responses for tokens, keys, PII | Dev assumes sensitive data is filtered; API returns everything |

---

## Evidence Collection

When you find a vulnerability:

```bash
# 1. Capture the request
mitmdump -nr session.mitm "~u /vulnerable/endpoint" -w evidence-001.mitm

# 2. Document reproduction
mitmdump -C evidence-001.mitm -B "/id=1/id=999" --flow-detail 4

# 3. Show before/after
mitmdump -nr evidence-001.mitm --flow-detail 3 > before.txt
mitmdump -C evidence-001.mitm -B "/id=1/id=999" -w exploited.mitm
mitmdump -nr exploited.mitm --flow-detail 3 > after.txt
diff before.txt after.txt
```

Report findings to `findings.md` with reproducible commands.

---

## Viewing Firewall Logs

```bash
# From repo root
docker-compose logs firewall

# Real-time
docker-compose logs -f firewall
```

SNI proxy logs show `[ALLOW]` and `[BLOCK]` with timestamps and domains.

---

## Troubleshooting

### Agent can't reach Claude API
```bash
# Check firewall is running
docker-compose ps

# Check logs for [BLOCK] entries
docker-compose logs firewall

# Test from inside container
curl -v https://api.anthropic.com
```

### Agent can't reach target
1. Verify target in `.env`: `grep TARGET .env`
2. Restart firewall: `docker-compose restart firewall`
3. Check logs: `docker-compose logs firewall | grep BLOCK`

### Atomizer not running
Check `.claude/hooks/query-atomization.sh` has execute permission:
```bash
ls -la .claude/hooks/
# Should show -rwxr--r-- (u+x)
```

---

## Documentation

- **[Agent Playbook](mitmproxy-ai-tool/CLAUDE.md)** — Filters, workflows, examples
- **[CLI Cheatsheet](mitmproxy-ai-tool/mitmdump-cheatsheet.md)** — Complete mitmdump reference
- **[Pentest Guide](mitmproxy-ai-tool/Mitmproxy_for_Penetration_Testing_A_Professional_Guide.md)** — Advanced techniques

---

## Security Notice

Designed for **authorized security testing only**:
- Bug bounty programs (explicit scope)
- Penetration testing (written authorization)
- Security research (your own applications)
- CTF competitions and training

The two-container architecture prevents accidental scope creep. The agent can only reach allowlisted targets and cannot see infrastructure configuration.

---

## Attribution

Built on:
- **[mitmproxy](https://mitmproxy.org/)** — Interactive intercepting proxy (MIT License)
- **[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/)** — Vulnerable web app for training (MIT License)

---

## License

MIT — See upstream projects for their respective licenses.
