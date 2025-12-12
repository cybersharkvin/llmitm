# mitmdump CLI Cheat Sheet
## For LLM-as-Operator Security Testing Workflow

mitmdump is the command-line interface to mitmproxy - think "tcpdump for HTTP." Unlike the interactive `mitmproxy` or web-based `mitmweb`, mitmdump is designed for scripting and automation. This makes it ideal for an LLM operating directly in a terminal.

---

## The Core Workflow

```
1. CAPTURE    →  mitmdump -w traffic.mitm "~d target.com"
2. ANALYZE    →  mitmdump -nr traffic.mitm "~m POST" --flow-detail 3
3. MUTATE     →  mitmdump -nr traffic.mitm -B "/param/payload" -w mutated.mitm
4. REPLAY     →  mitmdump -C mutated.mitm --flow-detail 3
5. OBSERVE    →  [read stdout, see what happened]
6. ITERATE    →  [adjust mutations based on responses]
```

---

## Part 1: Capturing Traffic

### Live Capture

Start a proxy that records everything passing through it:

```bash
mitmdump -w traffic.mitm
```
This starts a proxy on port 8080 and writes all flows to `traffic.mitm` as they happen. Point a browser or tool at `localhost:8080` to capture its traffic.

### Capture with Filters

Only capture what you care about:

```bash
# Only traffic to a specific domain
mitmdump -w traffic.mitm "~d api.target.com"

# Only POST requests
mitmdump -w traffic.mitm "~m POST"

# Only requests to authentication endpoints
mitmdump -w traffic.mitm "~u /auth|/login|/oauth"

# Combine filters: POSTs to target domain
mitmdump -w traffic.mitm "~d target.com & ~m POST"
```

### Change the Listen Port

```bash
mitmdump -p 9090 -w traffic.mitm
```

### Reverse Proxy Mode

Instead of a forward proxy (browser → proxy → anywhere), point at a specific backend:

```bash
mitmdump -p 8080 -m reverse:https://api.target.com -w traffic.mitm
```
Now anything hitting `localhost:8080` gets forwarded to `api.target.com` and recorded.

---

## Part 2: Analyzing Captured Traffic

The `-n` flag means "don't start a proxy server" and `-r` means "read from file." Together, `-nr` lets you process saved traffic offline.

### View Everything in a Capture

```bash
mitmdump -nr traffic.mitm
```
Prints a summary of every flow in the file.

### Control Output Verbosity

```bash
--flow-detail 0   # Silent - no output
--flow-detail 1   # Default - one line per flow (URL + status)
--flow-detail 2   # Include headers
--flow-detail 3   # Include headers + truncated body
--flow-detail 4   # Full headers + full body (verbose!)
```

Example - see full request/response details:
```bash
mitmdump -nr traffic.mitm --flow-detail 3
```

### Filter During Analysis

Only show specific flows from a capture:

```bash
# Only POST requests
mitmdump -nr traffic.mitm "~m POST"

# Only responses with 500 errors
mitmdump -nr traffic.mitm "~c 500"

# Only requests containing "password" in the body
mitmdump -nr traffic.mitm "~bq password"

# Only responses with JSON content
mitmdump -nr traffic.mitm "~ts application/json"

# Requests to /api/* that got 4xx or 5xx responses
mitmdump -nr traffic.mitm "~u /api & (~c 4.. | ~c 5..)"
```

### Save Filtered Results

Extract a subset of flows to a new file:

```bash
# Pull out just the auth-related requests
mitmdump -nr traffic.mitm "~u /auth" -w auth-flows.mitm
```

---

## Part 3: Modifying Traffic

You can modify flows either during live proxying OR when processing saved files. These flags work in both contexts.

### Modify Headers (`-H`)

Pattern: `/filter/header-name/header-value`

```bash
# Add a header to all requests
mitmdump -H "/~q/X-Custom-Header/injected-value"

# Change User-Agent on all requests
mitmdump -H "/~q/User-Agent/EvilBot 1.0"

# Add auth header to requests going to /api
mitmdump -H "/~q & ~u /api/Authorization/Bearer stolen-token"

# Remove a header (empty value = delete)
mitmdump -H "/~q/Cookie/"

# Modify response headers
mitmdump -H "/~s/X-Frame-Options/"
```

### Modify Body (`-B`)

Pattern: `/filter/regex/replacement`

```bash
# Replace "admin" with "superadmin" in request bodies
mitmdump -B "/~q/admin/superadmin"

# Inject into JSON - change role field
mitmdump -B '/~q/"role":"user"/"role":"admin"/'

# Replace in responses
mitmdump -B "/~s/Access Denied/Access Granted"

# Use a file for the replacement payload
mitmdump -B "/~q/FUZZ/@/home/user/payload.txt"
```

### Map Remote (`-M`)

Redirect requests to different URLs:

```bash
# Redirect all requests from prod to staging
mitmdump -M "|//api.prod.com|//api.staging.com"

# Redirect specific endpoints
mitmdump -M "|/api/v1/|/api/v2/"
```

### Map Local (`--map-local`)

Serve local files instead of making real requests:

```bash
# Return a local file for a specific endpoint
mitmdump --map-local "|example.com/api/config|~/mock-config.json"

# Serve an entire directory
mitmdump --map-local "|example.com/static|~/local-static/"
```

### Block Requests (`--set block_list`)

Block requests entirely, return a status code:

```bash
# Block analytics, return 404
mitmdump --set block_list="/~d google-analytics.com/404"

# Block and hang (no response at all) - status 444
mitmdump --set block_list="/~d tracking.com/444"
```

---

## Part 4: Replaying Traffic

### Client Replay (`-C`)

Replay saved requests against a live server:

```bash
# Replay all requests from a file
mitmdump -C traffic.mitm

# Replay with verbose output to see responses
mitmdump -C traffic.mitm --flow-detail 3

# Replay but modify requests on the way out
mitmdump -C traffic.mitm -H "/~q/X-Test/fuzz-value"

# Replay and save the new responses
mitmdump -C traffic.mitm -w replayed.mitm
```

Requests are replayed sequentially by default (one at a time, waiting for response). Control concurrency with `--set client_replay_concurrency=N`.

### Server Replay (`-S`)

Replay saved *responses* - useful for mocking:

```bash
# Act as a mock server returning saved responses
mitmdump -S recorded-responses.mitm
```

When a request comes in that matches a saved request, return the saved response instead of forwarding.

### Offline Mutation Then Replay

A common pattern - modify saved traffic, save the mutations, then replay:

```bash
# Step 1: Mutate saved traffic offline, write to new file
mitmdump -nr original.mitm -B "/~q/user/admin" -w mutated.mitm

# Step 2: Replay the mutated traffic
mitmdump -C mutated.mitm --flow-detail 3
```

Or do it inline (modify during replay):

```bash
mitmdump -C original.mitm -B "/~q/user/admin" --flow-detail 3
```

---

## Part 5: Filter Expression Reference

Filters are how you select which flows to capture, display, modify, or replay. They use a tilde (`~`) prefix.

### Request vs Response

| Filter | Matches |
|--------|---------|
| `~q` | Requests (flows that haven't received a response yet) |
| `~s` | Responses (flows that have received a response) |

Most modification filters need `~q` (modify request) or `~s` (modify response) to specify which direction.

### URL and Domain

| Filter | Matches |
|--------|---------|
| `~u regex` | URL matches regex |
| `~d regex` | Domain matches regex |
| `example.com` | Shorthand - bare string matches URL |

```bash
~u /api/v1/users      # URL contains /api/v1/users
~u "^https://.*\.json$"  # URL starts with https, ends with .json
~d target.com         # Domain is target.com
~d ".*\.target\.com"  # Any subdomain of target.com
```

### Method

| Filter | Matches |
|--------|---------|
| `~m METHOD` | HTTP method |

```bash
~m GET
~m POST
~m "PUT|PATCH|DELETE"  # Any of these methods
```

### Status Code

| Filter | Matches |
|--------|---------|
| `~c CODE` | Response status code |

```bash
~c 200          # Exactly 200
~c 500          # Exactly 500
~c "4.."        # Any 4xx (400-499)
~c "5.."        # Any 5xx
~c "4.. | 5.."  # Any error
```

### Headers

| Filter | Matches |
|--------|---------|
| `~h regex` | Any header (request or response) |
| `~hq regex` | Request header |
| `~hs regex` | Response header |

Headers match against `name: value` format:

```bash
~hq "Authorization"           # Request has Authorization header
~hq "Authorization: Bearer"   # Auth header starting with Bearer
~hs "Set-Cookie"              # Response sets a cookie
~h "Content-Type: application/json"  # JSON content anywhere
```

### Body Content

| Filter | Matches |
|--------|---------|
| `~b regex` | Body (request or response) |
| `~bq regex` | Request body |
| `~bs regex` | Response body |

```bash
~bq password              # Request body contains "password"
~bq "username.*password"  # Request has both (in order)
~bs "error"               # Response contains "error"
~bs "token.*[a-f0-9]{32}" # Response has something that looks like a token
```

### Content Type

| Filter | Matches |
|--------|---------|
| `~t regex` | Content-Type header |
| `~tq regex` | Request Content-Type |
| `~ts regex` | Response Content-Type |

```bash
~ts application/json    # JSON responses
~tq multipart           # Multipart form uploads
~t xml                  # XML anywhere
```

### Other Filters

| Filter | Matches |
|--------|---------|
| `~a` | Assets (CSS, JS, images, Flash) |
| `~e` | Errors (connection failures, timeouts) |
| `~all` | All flows |
| `~marked` | Manually marked flows |
| `~marker regex` | Flows with specific marker |
| `~comment regex` | Flow comment matches |
| `~meta regex` | Flow metadata matches |
| `~replay` | Replayed flows |
| `~replayq` | Replayed client requests |
| `~replays` | Replayed server responses |
| `~src regex` | Source address |
| `~dst regex` | Destination address |
| `~tcp` | Raw TCP flows |
| `~udp` | UDP flows |
| `~dns` | DNS flows |
| `~websocket` | WebSocket flows |
| `~http` | HTTP flows |

### Combining Filters

| Operator | Meaning |
|----------|---------|
| `&` | AND (both must match) |
| `\|` | OR (either can match) |
| `!` | NOT (negate) |
| `(...)` | Grouping |

```bash
# POST requests to /api
~m POST & ~u /api

# Errors OR server errors in response
~e | ~c "5.."

# Requests that are NOT assets
!~a

# POST or PUT requests to /api that returned errors
(~m POST | ~m PUT) & ~u /api & ~c "4.. | 5.."

# Everything except static assets on the target domain
~d target.com & !~a

# Auth requests with password in body but NOT to /logout
~u /auth & ~bq password & !~u /logout
```

---

## Part 6: Common Patterns

### Pattern: Capture → Filter → Analyze

```bash
# 1. Capture during manual browsing
mitmdump -w session.mitm

# 2. Find interesting requests
mitmdump -nr session.mitm "~m POST" --flow-detail 2

# 3. Look deeper at auth flows
mitmdump -nr session.mitm "~u /auth" --flow-detail 4
```

### Pattern: Extract and Fuzz a Parameter

```bash
# 1. Find requests with a specific parameter
mitmdump -nr session.mitm "~bq user_id" --flow-detail 3

# 2. Mutate and save
mitmdump -nr session.mitm "~bq user_id" -B "/user_id=123/user_id=456" -w fuzzed.mitm

# 3. Replay and observe
mitmdump -C fuzzed.mitm --flow-detail 3
```

### Pattern: Test for IDOR

```bash
# 1. Capture a request that fetches user data
mitmdump -w capture.mitm

# 2. Change the user ID and replay
mitmdump -C capture.mitm -B "/\"user_id\":1/\"user_id\":2" --flow-detail 3
```

### Pattern: Inject Headers for Auth Bypass

```bash
# Replay with admin header injection
mitmdump -C capture.mitm -H "/~q/X-User-Role/admin" --flow-detail 3

# Try common bypass headers
mitmdump -C capture.mitm -H "/~q/X-Forwarded-For/127.0.0.1" --flow-detail 3
mitmdump -C capture.mitm -H "/~q/X-Original-URL/admin/dashboard" --flow-detail 3
```

### Pattern: Response Analysis for Sensitive Data

```bash
# Find responses containing tokens or keys
mitmdump -nr session.mitm "~bs token|api_key|secret" --flow-detail 3

# Find responses containing emails
mitmdump -nr session.mitm '~bs "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"' --flow-detail 3
```

### Pattern: Compare Before/After

```bash
# Save original responses
mitmdump -C original-requests.mitm -w original-responses.mitm

# Modify and save new responses
mitmdump -C original-requests.mitm -B "/role=user/role=admin" -w modified-responses.mitm

# Analyze both (manually compare or diff the output)
mitmdump -nr original-responses.mitm "~c 200" --flow-detail 3 > original.txt
mitmdump -nr modified-responses.mitm "~c 200" --flow-detail 3 > modified.txt
diff original.txt modified.txt
```

---

## Part 7: Quick Reference

### Flags Summary

| Flag | Long Form | Purpose |
|------|-----------|---------|
| `-p` | `--listen-port` | Proxy port (default 8080) |
| `-m` | `--mode` | Proxy mode (regular, local, transparent, socks5, reverse, upstream, wireguard) |
| `-w` | `--save-stream-file` | Write flows to file |
| `-r` | `--rfile` | Read flows from file |
| `-n` | `--no-server` | Don't start proxy (offline mode) |
| `-C` | `--client-replay` | Replay client requests |
| `-S` | `--server-replay` | Replay server responses |
| `-s` | `--scripts` | Run Python script |
| `-H` | `--modify-headers` | Modify headers |
| `-B` | `--modify-body` | Modify body |
| `-M` | `--map-remote` | Redirect URLs |
| `-q` | `--quiet` | Suppress output |
| | `--flow-detail N` | Output verbosity (0-4) |
| `-k` | `--ssl-insecure` | Ignore SSL cert errors |

### Filter Quick Reference

| Category | Filters |
|----------|---------|
| Direction | `~q` (request), `~s` (response) |
| URL/Domain | `~u`, `~d`, bare string |
| Method | `~m GET`, `~m POST`, etc. |
| Status | `~c 200`, `~c "4.."` |
| Headers | `~h`, `~hq`, `~hs` |
| Body | `~b`, `~bq`, `~bs` |
| Content-Type | `~t`, `~tq`, `~ts` |
| Special | `~a` (assets), `~e` (errors) |
| Operators | `&` (and), `\|` (or), `!` (not), `()` (group) |

### Modification Pattern Syntax

All modification flags use the same pattern structure:
```
/filter/target/replacement
```

The separator (first character) is arbitrary - use whatever isn't in your pattern:
```bash
# Using / as separator
-B "/~q/foo/bar"

# Using | when pattern contains /
-B "|~q|/api/v1|/api/v2"

# Using : when pattern contains | and /
-H ":~q:Host:evil.com"
```

---

## Part 8: Useful Options

View all available options:
```bash
mitmdump --options
```

### Commonly Useful Options

```bash
# Don't verify SSL certs (for self-signed targets)
--ssl-insecure

# Strip cache headers (always get fresh responses)
--anticache

# Decompress responses (easier to read/modify)
--anticomp

# Only allow specific hosts
--allow-hosts "target\.com"

# Ignore specific hosts (pass through without capture)
--ignore-hosts "fonts\.googleapis\.com"

# Set body size limit (skip huge files)
--set body_size_limit=1m
```

### Config File

Instead of passing flags every time, create `~/.mitmproxy/config.yaml`:

```yaml
anticache: true
anticomp: true
ssl_insecure: true
flow_detail: 2
```

---

## Notes

- Flows are saved in a binary format - you can only read them with mitmdump/mitmproxy
- The filter in the positional argument applies to both viewing AND saving
- Use `-q` (quiet) when you only want to write to file, not see output
- Regex is Python-style regex
- All matching is case-insensitive by default
