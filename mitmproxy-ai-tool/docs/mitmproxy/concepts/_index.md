---
title: "Core Concepts"
---

# Core Concepts

Fundamental concepts for understanding how mitmproxy works and how to use it effectively for traffic interception and analysis.

## In This Section

| Document | Description |
|----------|-------------|
| [How Mitmproxy Works](how-mitmproxy-works.md) | Architecture and internal flow of traffic interception |
| [Modes](modes.md) | Proxy operation modes: regular, transparent, reverse, upstream |
| [Certificates](certificates.md) | SSL/TLS certificate generation and installation for HTTPS interception |
| [Filter Expressions](filters.md) | Query syntax for selecting flows (`~d`, `~u`, `~m`, `~b`, `~c`, etc.) |
| [Options](options.md) | Configuration options and how to set them |
| [Commands](commands.md) | Built-in commands for flow manipulation |
| [Protocols](protocols.md) | Supported protocols: HTTP/1, HTTP/2, WebSocket, TCP, DNS |

## Key Concepts for LLM Operation

- **Filter expressions** are essential for targeting specific traffic (e.g., `~d api.example.com ~m POST`)
- **Modes** determine how traffic is routed through the proxy
- **Certificates** must be installed for HTTPS interception to work 