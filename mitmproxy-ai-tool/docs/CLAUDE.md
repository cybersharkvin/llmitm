# Mitmproxy Documentation Reference

**Purpose:** Exhaustive navigation for the mitmproxy documentation. Use this when building new cheatsheets, guides, or researching specific topics.

For operational use (security testing workflows), see the root [../CLAUDE.md](../CLAUDE.md).

---

## Documentation Map

### Overview Section
| Document | Description | Path |
|----------|-------------|------|
| **Introduction** | mitmproxy tools overview (mitmproxy, mitmweb, mitmdump) | [mitmproxy/_index.md](mitmproxy/_index.md) |
| **Getting Started** | First-time setup and configuration | [mitmproxy/overview/getting-started.md](mitmproxy/overview/getting-started.md) |
| **Installation** | Platform-specific installation (pip, brew, binaries) | [mitmproxy/overview/installation.md](mitmproxy/overview/installation.md) |
| **Features** | Anticache, blocklist, replay, map local/remote, modify headers/body | [mitmproxy/overview/features.md](mitmproxy/overview/features.md) |

### Core Concepts Section
| Document | Description | Path |
|----------|-------------|------|
| **How Mitmproxy Works** | Architecture, traffic flow, interception mechanism | [mitmproxy/concepts/how-mitmproxy-works.md](mitmproxy/concepts/how-mitmproxy-works.md) |
| **Modes** | Regular, transparent, reverse, upstream, SOCKS5, local | [mitmproxy/concepts/modes.md](mitmproxy/concepts/modes.md) |
| **Certificates** | TLS interception, CA generation, certificate installation | [mitmproxy/concepts/certificates.md](mitmproxy/concepts/certificates.md) |
| **Filter Expressions** | Complete filter syntax: `~d`, `~u`, `~m`, `~b`, `~c`, `~h`, operators | [mitmproxy/concepts/filters.md](mitmproxy/concepts/filters.md) |
| **Options** | All configuration options, config file format | [mitmproxy/concepts/options.md](mitmproxy/concepts/options.md) |
| **Commands** | Built-in flow manipulation commands | [mitmproxy/concepts/commands.md](mitmproxy/concepts/commands.md) |
| **Protocols** | HTTP/1, HTTP/2, HTTP/3, WebSocket, TCP, UDP, DNS support | [mitmproxy/concepts/protocols.md](mitmproxy/concepts/protocols.md) |

### Addon Development Section
| Document | Description | Path |
|----------|-------------|------|
| **Addon Overview** | Addon architecture, lifecycle, registration | [mitmproxy/addons/overview.md](mitmproxy/addons/overview.md) |
| **Event Hooks** | All hooks: `request`, `response`, `load`, `configure`, connection events | [mitmproxy/addons/event-hooks.md](mitmproxy/addons/event-hooks.md) |
| **Options** | Defining custom addon options with typing | [mitmproxy/addons/options.md](mitmproxy/addons/options.md) |
| **Commands** | Creating addon commands callable from mitmproxy | [mitmproxy/addons/commands.md](mitmproxy/addons/commands.md) |
| **Content Views** | Custom content rendering for specific data formats | [mitmproxy/addons/contentviews.md](mitmproxy/addons/contentviews.md) |
| **Examples** | Practical addon code examples | [mitmproxy/addons/examples.md](mitmproxy/addons/examples.md) |
| **API Changelog** | Breaking changes, migration notes between versions | [mitmproxy/addons/api-changelog.md](mitmproxy/addons/api-changelog.md) |

### Python API Section
| Document | Description | Path |
|----------|-------------|------|
| **mitmproxy.http** | `Request`, `Response`, `Headers`, `Message` classes | [mitmproxy/api/mitmproxy.http.md](mitmproxy/api/mitmproxy.http.md) |
| **mitmproxy.flow** | Flow objects representing request/response pairs | [mitmproxy/api/mitmproxy.flow.md](mitmproxy/api/mitmproxy.flow.md) |
| **mitmproxy.connection** | `Client`, `Server` connection objects | [mitmproxy/api/mitmproxy.connection.md](mitmproxy/api/mitmproxy.connection.md) |
| **mitmproxy.tcp** | `TCPFlow`, `TCPMessage` for raw TCP handling | [mitmproxy/api/mitmproxy.tcp.md](mitmproxy/api/mitmproxy.tcp.md) |
| **mitmproxy.websocket** | `WebSocketMessage` for WebSocket traffic | [mitmproxy/api/mitmproxy.websocket.md](mitmproxy/api/mitmproxy.websocket.md) |
| **mitmproxy.dns** | `DNSFlow`, `DNSMessage` for DNS interception | [mitmproxy/api/mitmproxy.dns.md](mitmproxy/api/mitmproxy.dns.md) |

### Tutorials Section
| Document | Description | Path |
|----------|-------------|------|
| **Client Replay** | Re-sending captured requests, response comparison | [mitmproxy/tutorials/client-replay.md](mitmproxy/tutorials/client-replay.md) |
| **Highscores** | Traffic modification example (game score manipulation) | [mitmproxy/tutorials/highscores.md](mitmproxy/tutorials/highscores.md) |

### HOWTOs Section
| Document | Description | Path |
|----------|-------------|------|
| **Ignore Domains** | Bypassing interception for specific domains | [mitmproxy/howto/ignore-domains.md](mitmproxy/howto/ignore-domains.md) |
| **Transparent Proxy** | Transparent mode setup on Linux/macOS | [mitmproxy/howto/transparent.md](mitmproxy/howto/transparent.md) |
| **Transparent VMs** | VM traffic interception configuration | [mitmproxy/howto/transparent-vms.md](mitmproxy/howto/transparent-vms.md) |
| **Kubernetes** | K8s sidecar deployment, service mesh integration | [mitmproxy/howto/kubernetes.md](mitmproxy/howto/kubernetes.md) |
| **Android CA Install** | System CA installation for mobile app testing | [mitmproxy/howto/install-system-trusted-ca-android.md](mitmproxy/howto/install-system-trusted-ca-android.md) |
| **Wireshark TLS** | TLS key export for Wireshark decryption | [mitmproxy/howto/wireshark-tls.md](mitmproxy/howto/wireshark-tls.md) |

### CLI Video Tutorials Section
| Document | Description | Path |
|----------|-------------|------|
| **User Interface** | Console UI navigation | [mitmproxy/cli-tutorials/cli-01-user-interface.md](mitmproxy/cli-tutorials/cli-01-user-interface.md) |
| **Intercept Requests** | Setting up interception | [mitmproxy/cli-tutorials/cli-02-intercept-requests.md](mitmproxy/cli-tutorials/cli-02-intercept-requests.md) |
| **Modify Requests** | Request editing in console | [mitmproxy/cli-tutorials/cli-03-modify-requests.md](mitmproxy/cli-tutorials/cli-03-modify-requests.md) |
| **Replay Requests** | Traffic replay | [mitmproxy/cli-tutorials/cli-04-replay-requests.md](mitmproxy/cli-tutorials/cli-04-replay-requests.md) |
| **What's Next** | Additional resources | [mitmproxy/cli-tutorials/whats-next.md](mitmproxy/cli-tutorials/whats-next.md) |

### Web UI Video Tutorials Section
| Document | Description | Path |
|----------|-------------|------|
| **User Interface** | mitmweb UI overview | [mitmproxy/web-tutorials/web-01-user-interface.md](mitmproxy/web-tutorials/web-01-user-interface.md) |
| **Intercepting Traffic** | Capturing in mitmweb | [mitmproxy/web-tutorials/web-02-intercepting-traffic.md](mitmproxy/web-tutorials/web-02-intercepting-traffic.md) |
| **Analysing Flows** | Flow inspection | [mitmproxy/web-tutorials/web-03-analysing-flows.md](mitmproxy/web-tutorials/web-03-analysing-flows.md) |
| **Modifying Requests** | Request editing in browser | [mitmproxy/web-tutorials/web-04-modifying-requests.md](mitmproxy/web-tutorials/web-04-modifying-requests.md) |
| **Replaying Flows** | Traffic replay in mitmweb | [mitmproxy/web-tutorials/web-05-replaying-flows.md](mitmproxy/web-tutorials/web-05-replaying-flows.md) |

---

## Cross-Reference: Topics by Concept

### Filter Expressions
- **Primary:** [concepts/filters.md](mitmproxy/concepts/filters.md) - Complete syntax reference
- **Usage in options:** [concepts/options.md](mitmproxy/concepts/options.md)
- **In features:** [overview/features.md](mitmproxy/overview/features.md) - Blocklist, map patterns

### Request/Response Modification
- **CLI flags:** [overview/features.md](mitmproxy/overview/features.md) - `-H`, `-B`, map local/remote
- **Addon hooks:** [addons/event-hooks.md](mitmproxy/addons/event-hooks.md) - `request()`, `response()`
- **API classes:** [api/mitmproxy.http.md](mitmproxy/api/mitmproxy.http.md) - `Request`, `Response` objects

### Traffic Replay
- **Feature overview:** [overview/features.md](mitmproxy/overview/features.md) - Client/server replay
- **Tutorial:** [tutorials/client-replay.md](mitmproxy/tutorials/client-replay.md)
- **CLI tutorial:** [cli-tutorials/cli-04-replay-requests.md](mitmproxy/cli-tutorials/cli-04-replay-requests.md)

### Certificate/TLS Interception
- **Concepts:** [concepts/certificates.md](mitmproxy/concepts/certificates.md) - CA generation, installation
- **Android setup:** [howto/install-system-trusted-ca-android.md](mitmproxy/howto/install-system-trusted-ca-android.md)
- **Wireshark integration:** [howto/wireshark-tls.md](mitmproxy/howto/wireshark-tls.md)

### Proxy Modes
- **Mode reference:** [concepts/modes.md](mitmproxy/concepts/modes.md) - All modes explained
- **Transparent setup:** [howto/transparent.md](mitmproxy/howto/transparent.md)
- **VM transparent:** [howto/transparent-vms.md](mitmproxy/howto/transparent-vms.md)

### Addon Development
- **Start here:** [addons/overview.md](mitmproxy/addons/overview.md)
- **All hooks:** [addons/event-hooks.md](mitmproxy/addons/event-hooks.md)
- **Code examples:** [addons/examples.md](mitmproxy/addons/examples.md)
- **HTTP API:** [api/mitmproxy.http.md](mitmproxy/api/mitmproxy.http.md)
- **Flow API:** [api/mitmproxy.flow.md](mitmproxy/api/mitmproxy.flow.md)

### Protocol-Specific
- **Overview:** [concepts/protocols.md](mitmproxy/concepts/protocols.md)
- **WebSocket API:** [api/mitmproxy.websocket.md](mitmproxy/api/mitmproxy.websocket.md)
- **TCP API:** [api/mitmproxy.tcp.md](mitmproxy/api/mitmproxy.tcp.md)
- **DNS API:** [api/mitmproxy.dns.md](mitmproxy/api/mitmproxy.dns.md)

---

## Section Index Files

Each section has an `_index.md` with its own TOC:

| Section | Index Path |
|---------|------------|
| Root | [mitmproxy/_index.md](mitmproxy/_index.md) |
| Overview | [mitmproxy/overview/_index.md](mitmproxy/overview/_index.md) |
| Concepts | [mitmproxy/concepts/_index.md](mitmproxy/concepts/_index.md) |
| Addons | [mitmproxy/addons/_index.md](mitmproxy/addons/_index.md) |
| API | [mitmproxy/api/_index.md](mitmproxy/api/_index.md) |
| Tutorials | [mitmproxy/tutorials/_index.md](mitmproxy/tutorials/_index.md) |
| HOWTOs | [mitmproxy/howto/_index.md](mitmproxy/howto/_index.md) |
| CLI Tutorials | [mitmproxy/cli-tutorials/_index.md](mitmproxy/cli-tutorials/_index.md) |
| Web Tutorials | [mitmproxy/web-tutorials/_index.md](mitmproxy/web-tutorials/_index.md) |

---

## File Count by Section

| Section | Count | Types |
|---------|-------|-------|
| Overview | 4 | Getting started, installation, features |
| Concepts | 8 | Architecture, modes, certs, filters, options, commands, protocols |
| Addons | 8 | Overview, hooks, options, commands, views, examples, changelog |
| API | 7 | http, flow, connection, tcp, websocket, dns |
| Tutorials | 3 | Client replay, highscores |
| HOWTOs | 7 | Ignore domains, transparent, VMs, k8s, Android, Wireshark |
| CLI Tutorials | 6 | UI, intercept, modify, replay, next |
| Web Tutorials | 6 | UI, intercept, analyse, modify, replay |
| **Total** | **49** | |
