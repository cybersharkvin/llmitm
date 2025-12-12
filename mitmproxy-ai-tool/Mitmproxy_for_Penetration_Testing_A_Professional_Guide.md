# Mitmproxy for Penetration Testing: A Professional Guide

**Mitmproxy is the most scriptable HTTP/HTTPS proxy available for penetration testers**, offering Python-based automation that outpaces GUI-focused alternatives like Burp Suite for workflow automation. This guide provides actionable techniques for bug bounty hunting and security assessments using mitmdump and the addon API, drawing from official documentation and security researcher practices.

The suite comprises three tools: **mitmproxy** (console interface), **mitmweb** (web UI), and **mitmdump** (command-line automation). Version 12.2.1 supports HTTP/1, HTTP/2, HTTP/3, WebSockets, TCP, UDP, and DNS interception with full TLS capabilities.

## Core mitmdump command-line usage

Mitmdump serves as the automation workhorse for penetration testing pipelines. The most critical flags for security work enable traffic capture, filtering, and scripted processing.

**Essential traffic capture commands:**
```bash
# Record all traffic with full detail
mitmdump -w evidence.mitm --flow-detail 3

# Process saved traffic with filters
mitmdump -n -r captured.mitm "~m POST" -w filtered.mitm

# Replay client requests for regression testing
mitmdump -n -C saved_requests.mitm --anticache

# Run addon script against live traffic
mitmdump -s scanner.py -w output.mitm
```

The `-n` flag disables proxy binding for offline processing, while `--flow-detail` controls output verbosity from **0** (silent) through **4** (full untruncated content). For evidence collection, level 3 provides headers plus truncated bodies suitable for bug bounty reports.

**Proxy mode selection** determines traffic interception method:
```bash
# Upstream proxy chain (route through Burp Suite on 8081)
mitmdump --mode upstream:http://127.0.0.1:8081 --ssl-insecure

# Transparent mode for network gateway scenarios
mitmdump --mode transparent --showhost --set block_global=false

# Reverse proxy targeting specific backend
mitmdump --mode reverse:https://api.target.com -p 8443

# Local application capture without system proxy
mitmdump --mode local:target-app-name

# SOCKS5 for tool integration
mitmdump --mode socks5 -p 1080
```

## Flow filtering eliminates noise during assessments

Mitmproxy's filter expressions use Python-style regex with powerful operators. Mastering filters dramatically improves signal-to-noise ratio during engagements.

| Filter | Purpose | Example |
|--------|---------|---------|
| `~d regex` | Domain matching | `~d api\.target\.com` |
| `~u regex` | URL path matching | `~u /api/v[12]/` |
| `~m method` | HTTP method | `~m POST\|PUT\|DELETE` |
| `~hq header` | Request header | `~hq Authorization` |
| `~hs header` | Response header | `~hs Set-Cookie` |
| `~bq regex` | Request body | `~bq password` |
| `~bs regex` | Response body | `~bs "error"\|"exception"` |
| `~c code` | Status code | `~c 401\|403\|500` |
| `~t content-type` | Content-Type | `~t application/json` |

**Combining filters for precision targeting:**
```bash
# API endpoints returning JSON errors
mitmdump "~d api.target.com & ~t json & ~c 400-599"

# POST requests with authentication tokens
mitmdump "~m POST & ~hq Authorization"

# Exclude static assets during analysis
mitmdump "!(~u \.(js|css|png|jpg|woff)$)"

# WebSocket traffic only
mitmdump "~websocket"
```

## SSL/TLS certificate handling enables HTTPS interception

Certificate installation is prerequisite for HTTPS interception. Mitmproxy generates certificates in `~/.mitmproxy/` on first run.

**Automated installation methods:**
```bash
# macOS (system keychain)
sudo security add-trusted-cert -d -p ssl -p basic \
    -k /Library/Keychains/System.keychain \
    ~/.mitmproxy/mitmproxy-ca-cert.pem

# Linux (update-ca-trust)
sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt
sudo update-ca-certificates

# Java applications
sudo keytool -importcert -alias mitmproxy -storepass changeit \
    -keystore $JAVA_HOME/lib/security/cacerts -trustcacerts \
    -file ~/.mitmproxy/mitmproxy-ca-cert.pem
```

For mobile testing, navigate to `http://mitm.it` with proxy configured for platform-specific installers. The certificate files serve different purposes: **mitmproxy-ca-cert.pem** for distribution, **mitmproxy-ca-cert.p12** for Windows/PKCS12 import, and **mitmproxy-ca-cert.cer** for Android.

**Certificate pinning bypass** requires additional tooling. The mitmproxy team maintains **android-unpinner** for APK modification:
```bash
# Install unpinner
uv tool install git+https://github.com/mitmproxy/android-unpinner

# Modify APK to remove pinning
android-unpinner all target-app.apk
```

For dynamic pin fetching, intercept and replace pins with your CA's hash:
```bash
# Generate pin value for your certificate
openssl x509 -in ~/.mitmproxy/mitmproxy-ca-cert.pem -pubkey -noout \
    | openssl pkey -pubin -outform der \
    | openssl dgst -sha256 -binary \
    | openssl enc -base64
```

## Python addon API enables sophisticated automation

The addon system provides hooks into every stage of request/response processing. A class-based structure with lifecycle methods forms the foundation for security testing automation.

**Production-grade addon skeleton:**
```python
"""Security testing addon with proper error handling."""
from mitmproxy import http, ctx
from mitmproxy.addonmanager import Loader
import logging

logger = logging.getLogger(__name__)

class SecurityAddon:
    def __init__(self):
        self.findings = []
    
    def load(self, loader: Loader):
        """Register custom options."""
        loader.add_option(
            name="target_domain",
            typespec=str,
            default="",
            help="Target domain for testing"
        )
    
    def request(self, flow: http.HTTPFlow) -> None:
        """Process outgoing requests."""
        try:
            if ctx.options.target_domain not in flow.request.host:
                return
            # Security testing logic here
        except Exception as e:
            logger.error(f"Request processing error: {e}")
    
    def response(self, flow: http.HTTPFlow) -> None:
        """Process incoming responses."""
        if flow.response and flow.response.status_code >= 400:
            logger.warning(f"Error response: {flow.response.status_code} {flow.request.pretty_url}")

addons = [SecurityAddon()]
```

**Key event hooks for security testing:**
- `request(flow)` — Modify requests before server transmission
- `responseheaders(flow)` — Enable streaming for large responses
- `response(flow)` — Analyze and modify complete responses
- `websocket_message(flow)` — Intercept WebSocket communications
- `error(flow)` — Handle connection failures
- `done()` — Cleanup on shutdown

### Request and response modification

Direct manipulation of HTTP traffic enables parameter tampering, header injection, and response modification:

```python
from mitmproxy import http
import json

def request(flow: http.HTTPFlow) -> None:
    # Inject testing headers
    flow.request.headers["X-Forwarded-For"] = "127.0.0.1"
    flow.request.headers["X-Security-Test"] = "active"
    
    # Modify query parameters
    flow.request.query["debug"] = "true"
    
    # Tamper with JSON body
    if flow.request.headers.get("content-type", "").startswith("application/json"):
        try:
            data = json.loads(flow.request.content)
            data["role"] = "admin"  # Privilege escalation attempt
            flow.request.content = json.dumps(data).encode()
        except json.JSONDecodeError:
            pass

def response(flow: http.HTTPFlow) -> None:
    # Remove security headers for testing
    for header in ["X-Frame-Options", "Content-Security-Policy", "X-XSS-Protection"]:
        if header in flow.response.headers:
            del flow.response.headers[header]
```

**Mock responses without server contact** enable testing against expected API behavior:
```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if "/api/admin" in flow.request.path:
        flow.response = http.Response.make(
            200,
            json.dumps({"access": "granted", "role": "admin"}).encode(),
            {"Content-Type": "application/json"}
        )
```

## Automated vulnerability detection patterns

Security researchers have developed reusable patterns for common vulnerability classes. These addons automate detection during passive traffic observation.

### JWT and session token interception

```python
"""JWT token capture and session persistence."""
from mitmproxy import http, ctx
import json
import re

class TokenInterceptor:
    JWT_PATTERN = re.compile(r'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*')
    
    def __init__(self):
        self.tokens = {}
        self.current_token = None
    
    def response(self, flow: http.HTTPFlow) -> None:
        if not flow.response:
            return
        
        # Check response body for tokens
        content = flow.response.get_text(strict=False) or ""
        jwt_matches = self.JWT_PATTERN.findall(content)
        
        if jwt_matches:
            self.current_token = jwt_matches[0]
            self.tokens[flow.request.host] = self.current_token
            ctx.log.warn(f"[TOKEN] Captured JWT from {flow.request.host}")
        
        # Check Set-Cookie for session tokens
        for cookie in flow.response.headers.get_all("set-cookie"):
            if any(k in cookie.lower() for k in ["session", "auth", "token", "jwt"]):
                ctx.log.warn(f"[SESSION] {flow.request.host}: {cookie[:80]}...")
    
    def request(self, flow: http.HTTPFlow) -> None:
        # Auto-inject captured tokens
        if self.current_token and flow.request.host in self.tokens:
            flow.request.headers["Authorization"] = f"Bearer {self.tokens[flow.request.host]}"

addons = [TokenInterceptor()]
```

### Credential and sensitive data detection

```python
"""Detect credentials and sensitive data in traffic."""
import re
import logging
from mitmproxy import http

logger = logging.getLogger(__name__)

class CredentialDetector:
    PATTERNS = {
        'password': re.compile(r'(password|passwd|pwd|secret)["\':]?\s*[:=]\s*["\']?([^"\'&\s]{4,})', re.I),
        'api_key': re.compile(r'(api[_-]?key|apikey|x-api-key)["\':]?\s*[:=]\s*["\']?([A-Za-z0-9_\-]{20,})', re.I),
        'bearer': re.compile(r'Bearer\s+([A-Za-z0-9_\-\.]{20,})', re.I),
        'jwt': re.compile(r'eyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'),
        'aws_key': re.compile(r'AKIA[0-9A-Z]{16}'),
        'private_key': re.compile(r'-----BEGIN\s+(?:RSA\s+)?PRIVATE\s+KEY-----'),
    }
    
    def request(self, flow: http.HTTPFlow) -> None:
        self._scan(flow, "REQUEST", flow.request.get_text(strict=False) or "")
        self._scan(flow, "REQ_HEADERS", str(dict(flow.request.headers)))
    
    def response(self, flow: http.HTTPFlow) -> None:
        if flow.response:
            self._scan(flow, "RESPONSE", flow.response.get_text(strict=False) or "")
    
    def _scan(self, flow, location, content):
        for name, pattern in self.PATTERNS.items():
            if pattern.search(content):
                logger.warning(f"[SENSITIVE] {name} detected in {location}: {flow.request.pretty_url}")

addons = [CredentialDetector()]
```

## Integration with security tool ecosystems

Mitmproxy chains effectively with specialized security tools, enabling hybrid workflows that combine its scripting power with purpose-built scanners.

### Burp Suite integration via upstream proxy

```bash
# Mitmproxy preprocesses traffic before Burp analysis
mitmdump --mode upstream:http://127.0.0.1:8081 \
    --ssl-insecure \
    -s preprocess.py

# Traffic flow: Client → mitmproxy:8080 → Burp:8081 → Internet
```

This configuration enables mitmproxy scripts to modify traffic before Burp's scanner analyzes it—useful for decompression, decryption, or header normalization.

### URL extraction for scanner integration

```python
"""Extract URLs for Nuclei, ffuf, or other scanners."""
from mitmproxy import http
import os

class URLExtractor:
    def __init__(self):
        self.seen = set()
        self.output = os.getenv("URL_FILE", "urls.txt")
    
    def request(self, flow: http.HTTPFlow) -> None:
        url = flow.request.pretty_url.split("?")[0]  # Base URL without params
        if url not in self.seen:
            self.seen.add(url)
            with open(self.output, "a") as f:
                f.write(url + "\n")

addons = [URLExtractor()]
```

**Scanner integration commands:**
```bash
# Collect URLs during browsing
mitmdump -s url_extractor.py

# Run Nuclei against collected endpoints
nuclei -l urls.txt -t /path/to/templates/ -proxy http://127.0.0.1:8080

# SQLmap through mitmproxy for traffic observation
sqlmap -u "http://target.com/page?id=1" --proxy=http://127.0.0.1:8080 --batch
```

### WebSocket interception for modern applications

```python
"""WebSocket message interception and modification."""
from mitmproxy import http, ctx

def websocket_message(flow: http.HTTPFlow):
    assert flow.websocket is not None
    msg = flow.websocket.messages[-1]
    
    direction = "CLIENT" if msg.from_client else "SERVER"
    ctx.log.info(f"[WS {direction}] {msg.text[:200] if msg.is_text else '[binary]'}")
    
    # Modify WebSocket messages
    if msg.is_text and "user_role" in msg.text:
        msg.content = msg.content.replace(b'"user_role":"user"', b'"user_role":"admin"')
```

## Professional configuration and best practices

### Performance optimization for large-scale testing

```bash
# Stream large responses to prevent memory issues
mitmdump --set stream_large_bodies=10m \
    --set body_size_limit=100m \
    --set connection_strategy=lazy \
    -q  # Quiet mode reduces logging overhead
```

**Ignore non-essential traffic:**
```bash
mitmdump --ignore-hosts '^(.+\.)?google-analytics\.com:' \
    --ignore-hosts '^(.+\.)?cloudflare\.com:' \
    --ignore-hosts '^(.+\.)?amazonaws\.com:' \
    --allow-hosts '^(.+\.)?targetapp\.com:'
```

### Transparent proxy mode deployment

For network gateway scenarios where client proxy configuration isn't possible:
```bash
#!/bin/bash
# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Create dedicated user to avoid routing loops
useradd --create-home mitmproxyuser

# Redirect traffic (excluding mitmproxy's own)
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser \
    --dport 80 -j REDIRECT --to-port 8080
iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner mitmproxyuser \
    --dport 443 -j REDIRECT --to-port 8080

# Run as dedicated user
sudo -u mitmproxyuser mitmproxy --mode transparent --showhost
```

### Docker deployment for isolated testing

```yaml
# docker-compose.yml
version: '3'
services:
  mitmproxy:
    image: mitmproxy/mitmproxy:latest
    volumes:
      - ./scripts:/scripts
      - ./certs:/home/mitmproxy/.mitmproxy
      - ./logs:/logs
    ports:
      - "8080:8080"
      - "8081:8081"  # mitmweb UI
    command: >
      mitmweb --web-host 0.0.0.0 
      -s /scripts/security_addon.py 
      -w /logs/traffic.mitm
```

### Configuration file for persistent settings

Create `~/.mitmproxy/config.yaml`:
```yaml
listen_port: 8080
ssl_insecure: true
anticomp: true          # Disable compression for inspection
anticache: true         # Prevent 304 responses
showhost: true          # Display Host header in transparent mode
flow_detail: 2
stream_large_bodies: 5m
ignore_hosts:
  - '.*\.google\.com'
  - '.*\.googleapis\.com'
  - '.*\.gstatic\.com'
```

## Command-line quick reference

| Task | Command |
|------|---------|
| Basic proxy | `mitmdump -p 8080` |
| Save traffic | `mitmdump -w traffic.mitm` |
| Load and filter | `mitmdump -nr traffic.mitm "~m POST" -w filtered.mitm` |
| Replay requests | `mitmdump -n -C requests.mitm` |
| Run addon | `mitmdump -s addon.py` |
| Chain to Burp | `mitmdump --mode upstream:http://127.0.0.1:8081` |
| Transparent mode | `mitmdump --mode transparent --showhost` |
| Reverse proxy | `mitmdump --mode reverse:https://api.target.com` |
| Modify headers | `mitmdump --modify-headers '/~q/X-Test/value'` |
| Modify body | `mitmdump --modify-body '/~q/search/replace'` |
| Block requests | `mitmdump --set "block_list=:~d ads.com:404"` |
| Export HAR | `mitmdump --set hardump=./capture.har` |

## Conclusion

Mitmproxy's strength lies in **programmatic control over HTTP traffic** that GUI tools cannot match. The addon API transforms passive interception into active security testing—automating credential detection, token manipulation, and vulnerability scanning across thousands of requests. For bug bounty hunters, the combination of filter expressions, Python scripting, and tool chain integration creates workflows that scale from manual exploration to automated reconnaissance.

Key differentiators for professional use: upstream proxy chaining preserves existing Burp workflows while adding scriptability; transparent mode enables testing without client configuration; and the `mitmdump` CLI integrates seamlessly into bash automation pipelines. Certificate pinning bypass through android-unpinner and Frida integration extends coverage to mobile applications that resist standard interception.