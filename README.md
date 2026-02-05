# LLMitM: Proof-of-Concept for Advanced LLM Architecture in Autonomous Pentesting

An autonomous bug bounty agent that demonstrates how to use LLMs correctly: leveraging terminal-native interfaces, structured memory as attention architecture, assumption-gap methodology, and semantic outsourcing to find vulnerabilities without the token overhead or reasoning degradation of traditional "AI security tools."

Built for [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) and other intentionally vulnerable applications.

**WARNING** This is NOT your generic AI hypebro tool. This is a methodological proof-of-concept backed by fundamental LLM architecture.

---

## Tl;Dr:

1. Start everything:
```bash
./setup.sh
export CLAUDE_API_KEY=sk-ant-...
cd mitmproxy-ai-tool && claude
```
2. Paste:
```
@CLAUDE.md we are beginning an initial hunt against the juice shop container. You MUST proceed with initial baselining and subsequent execution of the CAMRO workflow using the mitmdump CLI @docs/CLAUDE.md.

**You MUST update memory files regularly @.claude/memory/**

TARGET="http://juiceshop:3000"
```
3. Become 1337 h4ck3r

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
**The Model**: Claude Code's sandbox. Agent has full autonomy inside OS-level isolation it cannot escape.

**The Reality**:
- Sandbox enforces domain allowlist via proxy (HTTP_PROXY/HTTPS_PROXY)
- Filesystem writes restricted to working directory (bubblewrap/Seatbelt)
- `allowUnsandboxedCommands: false` — escape hatch disabled
- Settings not hot-reloaded — agent cannot modify its own boundaries mid-session
- Agent can run with `--dangerously-skip-permissions` safely

**Why This Matters**: Maximum agency + enforced boundaries. No Docker required. Deployable anywhere Claude Code runs.

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
Host OS (Linux/macOS)
├── Docker (only runs Juice Shop)
│   └── juiceshop container (port 3000 → host)
│
├── /etc/hosts: 127.0.0.1 juiceshop
│
└── Claude Code (host-native)
    └── bwrap sandbox (Linux) or Seatbelt (macOS)
        ├── Network namespace (loopback + socat bridges only)
        ├── HTTP_PROXY → socat → proxy on host
        ├── allowedDomains: [juiceshop, api.anthropic.com, ...]
        └── mitmproxy-ai-tool/ (working directory)
```

**Host-Native Sandbox**: Claude Code runs directly on the host OS. Its sandbox (bubblewrap on Linux, Seatbelt on macOS) creates an isolated environment with `HTTP_PROXY`/`HTTPS_PROXY` enforcing `allowedDomains` from `settings.json`. Docker's only job is running Juice Shop on port 3000. The `/etc/hosts` entry (`127.0.0.1 juiceshop`) lets the sandbox proxy resolve the hostname to localhost, where Docker port-maps to the Juice Shop container.

**Why a hostname, not an IP**: The sandbox's NO_PROXY list contains IP ranges (`172.16.0.0/12`, `10.0.0.0/8`, etc.). If you used a Docker container IP like `172.17.0.2`, curl would bypass the proxy and fail inside the network namespace. The hostname `juiceshop` avoids NO_PROXY matching, routes through the proxy, and resolves via the host's `/etc/hosts`.

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
CAPTURE  → curl http://juiceshop:3000/api/...       (respects HTTP_PROXY automatically)
           mitmdump --mode upstream:$HTTP_PROXY -p 8080 -w traffic.mitm &
           curl -x localhost:8080 http://juiceshop:3000/...  (richer .mitm capture)

ANALYZE  → mitmdump -nr traffic.mitm --flow-detail 3  (offline, no network)

MUTATE   → mitmdump -nr traffic.mitm -B "/user_id=1/user_id=2" -w test.mitm  (offline)

REPLAY   → curl with mutated params http://juiceshop:3000/...  (respects HTTP_PROXY)
           mitmdump --mode upstream:$HTTP_PROXY -C test.mitm --flow-detail 3

OBSERVE  → Analyze responses for vulnerability indicators
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

### Setup (Recommended)

The setup script checks dependencies, configures `/etc/hosts`, and starts Juice Shop:

```bash
./setup.sh                        # checks deps, adds /etc/hosts, starts Juice Shop
export CLAUDE_API_KEY=sk-ant-...  # or skip for OAuth login
cd mitmproxy-ai-tool && claude
```

### Manual Setup

If you prefer to set up manually:

```bash
# 1. Install prerequisites
pip install mitmproxy
curl -fsSL https://claude.ai/install.sh | sh
# Linux only: sudo apt install bubblewrap

# 2. Add /etc/hosts entry for Juice Shop
echo "127.0.0.1 juiceshop" | sudo tee -a /etc/hosts

# 3. Start Juice Shop
docker compose up -d

# 4. Launch
cd mitmproxy-ai-tool
claude
```

For non-Juice-Shop targets, edit `mitmproxy-ai-tool/.claude/settings.json` and add domains to `sandbox.network.allowedDomains`.

---

### Configure Targets

Edit `mitmproxy-ai-tool/.claude/settings.json`, add target domains to `sandbox.network.allowedDomains`:

```json
{
  "sandbox": {
    "network": {
      "allowedDomains": [
        "api.anthropic.com", "*.anthropic.com",
        "claude.ai", "*.claude.ai",
        "statsig.anthropic.com", "sentry.io", "*.sentry.io",
        "api.target.com",
        "cdn.target.com"
      ]
    }
  }
}
```

Or copy a profile:
```bash
cp mitmproxy-ai-tool/.claude/settings-profiles/settings-development.json \
   mitmproxy-ai-tool/.claude/settings.json
```

### Settings Profiles

| Profile | Use Case |
|---------|----------|
| `settings-lockdown.json` | Analysis only — Claude API, no targets |
| `settings-engagement.json.template` | Active engagement — replace TARGET placeholders |
| `settings-development.json` | Local targets (Juice Shop via /etc/hosts) |

---

### Launch Flags

Optional flags for advanced usage:

```bash
cd mitmproxy-ai-tool
claude --verbose \
       --permission-mode plan \
       --system-prompt-file ./.claude/agents/llmitm.md
```

**Flag explanations:**
- `--verbose` — Shows thinking cycles and token expenditure. Watch the atomizer's reasoning.
- `--permission-mode plan` — Starts in plan mode. Atomizer runs first (structured decomposition), then agent executes.
- `--system-prompt-file ./.claude/agents/llmitm.md` — Direct prompt loading. Avoids the `--agent llmitm` flag which causes context bleed with the atomizer hook.

Safe to use `--dangerously-skip-permissions` — sandbox enforces containment, not permissions.

---

### Your First Hunt

After signing in to Claude Code, paste:

```
@CLAUDE.md we are beginning an initial hunt against the juice shop container. You MUST proceed with initial baselining and subsequent execution of the CAMRO workflow using the mitmdump CLI.

Reference @.claude/memory/ for state, @docs/ for documentation.

You MUST update memory files (session.md, hypotheses.md, findings.md) after each phase.

TARGET="http://juiceshop:3000"
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
llmitm/
├── README.md                        # This file
├── setup.sh                         # Setup script (deps, /etc/hosts, Juice Shop)
├── docker-compose.yml               # Juice Shop only
├── .env.example                     # API key config
│
└── mitmproxy-ai-tool/               # Agent workspace (Claude Code runs here)
    ├── .claude/
    │   ├── agents/
    │   │   └── llmitm.md            # Agent system prompt
    │   ├── hooks/
    │   │   └── query-atomization.sh # Atomizer hook
    │   ├── memory/
    │   │   ├── session.md           # Operational state
    │   │   ├── hypotheses.md        # Test theories + failures
    │   │   └── findings.md          # Proven vulnerabilities
    │   ├── settings.json            # Sandbox + hooks (PRIMARY security config)
    │   └── settings-profiles/       # Pre-built profiles
    │       ├── settings-lockdown.json
    │       ├── settings-engagement.json.template
    │       └── settings-development.json
    ├── captures/                    # Traffic files (.mitm)
    ├── certs/                       # mitmproxy CA certificates
    ├── CLAUDE.md                    # Agent playbook (cross-linked)
    ├── mitmdump-cheatsheet.md       # CLI reference
    ├── llmitm-juiceshop.sh          # Juice Shop launcher
    └── docs/
        ├── CLAUDE.md                # Hub for documentation
        └── [deeper guides]
```

**Security boundary**: `settings.json` controls what domains are reachable. Claude Code's sandbox (bubblewrap/Seatbelt) enforces this at OS level on the host.

---

## Configuration

### Target Allowlist

Edit `mitmproxy-ai-tool/.claude/settings.json`:

```json
{
  "sandbox": {
    "network": {
      "allowedDomains": [
        "api.anthropic.com", "*.anthropic.com",
        "claude.ai", "*.claude.ai",
        "statsig.anthropic.com", "sentry.io", "*.sentry.io",
        "api.target.com",
        "cdn.target.com"
      ]
    }
  }
}
```

**Always allowed** (required by Claude Code):
- `api.anthropic.com` — Claude API
- `claude.ai` — Claude API
- `statsig.anthropic.com` — Telemetry
- `sentry.io` — Error reporting

### Verify Network Isolation

```bash
# From inside Claude session:

# Should SUCCEED (Claude API)
curl -I https://api.anthropic.com

# Should FAIL (not allowlisted)
curl -I https://google.com
```

---

## Docker Details

Docker's only job is running Juice Shop. Claude Code and its sandbox run **on the host**, not inside Docker.

```bash
docker compose up -d        # Starts Juice Shop on port 3000
docker compose down          # Stops Juice Shop
```

The `/etc/hosts` entry (`127.0.0.1 juiceshop`) maps the hostname to localhost. Docker's port mapping (`3000:3000`) forwards to the container. The sandbox proxy resolves `juiceshop` from the host's `/etc/hosts` since it runs outside the sandbox.

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
# Probe with curl (respects HTTP_PROXY automatically inside sandbox)
curl http://juiceshop:3000/api/...

# Capture via mitmdump (needs upstream proxy in sandbox)
mitmdump --mode upstream:$HTTP_PROXY -p 8080 -w captures/traffic.mitm &
curl -x http://localhost:8080 http://juiceshop:3000/api/...

# Analyze (read offline — no network needed)
mitmdump -nr captures/traffic.mitm --flow-detail 3

# IDOR test (swap user ID — offline mutation)
mitmdump -nr captures/traffic.mitm -B "/user_id=123/user_id=456" -w captures/idor.mitm

# Replay with upstream proxy
mitmdump --mode upstream:$HTTP_PROXY -C captures/idor.mitm --flow-detail 3

# Find sensitive data (offline)
mitmdump -nr captures/traffic.mitm "~bs password|token|api_key|secret" --flow-detail 3
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
# 1. Extract the vulnerable request (offline)
mitmdump -nr captures/session.mitm "~u /vulnerable/endpoint" -w captures/evidence-001.mitm

# 2. Document reproduction (needs upstream proxy for replay)
mitmdump --mode upstream:$HTTP_PROXY -C captures/evidence-001.mitm -B "/id=1/id=999" --flow-detail 4

# 3. Show before/after
mitmdump -nr captures/evidence-001.mitm --flow-detail 3 > before.txt
mitmdump --mode upstream:$HTTP_PROXY -C captures/evidence-001.mitm -B "/id=1/id=999" -w captures/exploited.mitm
mitmdump -nr captures/exploited.mitm --flow-detail 3 > after.txt
diff before.txt after.txt
```

Report findings to `findings.md` with reproducible commands.

---

## Migrating from Previous Versions

### From v1.5 (Docker agent container)
1. Delete local Dockerfile (no longer needed)
2. Add `/etc/hosts` entry: `echo "127.0.0.1 juiceshop" | sudo tee -a /etc/hosts`
3. `docker compose up -d` now only starts Juice Shop
4. Run Claude Code on host: `cd mitmproxy-ai-tool && claude`

### From v1.0 (Docker two-container + firewall sidecar)
1. `TARGET_DOMAINS` from `.env` → `allowedDomains` in `settings.json`
2. `./launch.sh` → `./setup.sh && cd mitmproxy-ai-tool && claude`
3. Docker two-container setup → Host-native sandbox + Docker Juice Shop only
4. Rollback: `git checkout v1.0-final`

---

## Troubleshooting

### Agent can't reach Juice Shop
1. Verify `/etc/hosts` has `127.0.0.1 juiceshop`: `grep juiceshop /etc/hosts`
2. Verify Juice Shop is running: `curl http://juiceshop:3000/`
3. Check `allowedDomains` in `settings.json` includes `juiceshop`
4. Restart Claude Code session (settings not hot-reloaded)

### Agent can't reach any target
1. Check `allowedDomains` in `settings.json`
2. Restart Claude Code session (settings not hot-reloaded)
3. Verify sandbox is enabled: look for `HTTP_PROXY` env var in Bash output

### mitmdump can't reach targets
mitmdump does NOT respect `HTTP_PROXY`/`HTTPS_PROXY`. For network operations, use:
```bash
mitmdump --mode upstream:$HTTP_PROXY -p 8080 -w captures/session.mitm
```
Offline operations (`-nr`, `-B`) don't need network and work as-is.

### Sandbox not working (Linux)
1. Check bubblewrap: `which bwrap`
2. Install: `sudo apt install bubblewrap`

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

The Claude Code sandbox prevents accidental scope creep. The agent can only reach allowlisted targets via OS-level proxy enforcement.

---

## Attribution

Built on:
- **[mitmproxy](https://mitmproxy.org/)** — Interactive intercepting proxy (MIT License)
- **[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/)** — Vulnerable web app for training (MIT License)

---

## License

MIT — See upstream projects for their respective licenses.
