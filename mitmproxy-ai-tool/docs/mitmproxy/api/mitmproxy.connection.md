---
title: "mitmproxy.connection"
url: "api/mitmproxy/connection.html"
menu: api
---

# mitmproxy.connection API

The `mitmproxy.connection` module provides base classes for managing client and server connections, including metadata about network addresses, TLS configuration, and connection state.

## ConnectionState

An enumeration representing the current state of the underlying socket.

| Member | Value | Description |
|--------|-------|-------------|
| `CLOSED` | 0 | Socket is closed |
| `CAN_READ` | 1 | Socket can read data |
| `CAN_WRITE` | 2 | Socket can write data |
| `OPEN` | 3 | Socket is open (CAN_READ \| CAN_WRITE) |

## Connection

Base class for client and server connections. The connection object only exposes metadata about the connection, but not the underlying socket object.

**Key Attributes:**
| Attribute | Type | Description |
|-----------|------|-------------|
| `peername` | tuple | Remote `(ip, port)` tuple |
| `sockname` | tuple | Local `(ip, port)` tuple |
| `state` | ConnectionState | Current connection state |
| `id` | str | Unique UUID identifier |
| `transport_protocol` | str | "tcp" or "udp" |
| `error` | str \| None | Error description for failed connections |
| `tls` | bool | Whether TLS should be established |
| `certificate_list` | list | TLS certificates sent by peer |
| `alpn` | bytes \| None | Negotiated application-layer protocol |
| `alpn_offers` | list | ALPN offers from ClientHello |
| `cipher` | str \| None | Active cipher name |
| `sni` | str \| None | Server Name Indication from ClientHello |
| `tls_version` | str \| None | Active TLS version |
| `timestamp_start` | float \| None | Connection start timestamp |
| `timestamp_end` | float \| None | Connection end timestamp |
| `timestamp_tls_setup` | float \| None | TLS handshake completion timestamp |

**Properties:**
| Property | Description |
|----------|-------------|
| `connected` | True if state is OPEN |
| `tls_established` | True if TLS handshake completed |

## Client

Represents a connection between a client and mitmproxy.

**Specific Attributes:**
| Attribute | Description |
|-----------|-------------|
| `peername` | Client's address (required) |
| `sockname` | Local address connection received on (required) |
| `mitmcert` | Certificate used by mitmproxy for TLS |
| `proxy_mode` | Proxy server type |
| `timestamp_start` | TCP SYN received timestamp |

## Server

Represents a connection between mitmproxy and an upstream server.

**Specific Attributes:**
| Attribute | Description |
|-----------|-------------|
| `address` | Server's `(host, port)` tuple (required) |
| `peername` | Resolved server `(ip, port)` tuple |
| `timestamp_tcp_setup` | TCP ACK received timestamp |
| `via` | Optional upstream proxy specification |

**Note:** Prevents modification of `address` and `via` attributes when connection is open.

## Type Aliases

- `TransportProtocol`: Literal["tcp", "udp"]
- `TlsVersion`: Supports SSLv3, TLSv1.0-1.3, DTLSv0.9-1.2, QUICv1
- `Address`: tuple[str, int]

## Usage Examples

### Checking Connection State

```python
def client_connected(client):
    print(f"Client connected from {client.peername}")
    print(f"TLS: {client.tls}")
```

### Accessing Server Details

```python
def server_connected(data):
    server = data.server
    print(f"Connected to {server.address}")
    print(f"Resolved IP: {server.peername}")
    if server.tls_established:
        print(f"TLS version: {server.tls_version}")
        print(f"Cipher: {server.cipher}")
```
