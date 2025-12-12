---
title: "mitmproxy.tcp"
url: "api/mitmproxy/tcp.html"
menu: api
---

# mitmproxy.tcp API

The `mitmproxy.tcp` module provides classes for handling TCP connections and messages within mitmproxy's proxy framework.

## TCPMessage

A representation of an individual TCP message within a stream.

**Important Note:** TCP is *stream-based* and not *message-based*. For practical purposes the stream is chunked into messages here, but you should not rely on message boundaries.

### Constructor

```python
TCPMessage(from_client: bool, content: bytes, timestamp: float = None)
```

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `from_client` | bool | True if message is from client to server |
| `content` | bytes | The message payload/data |
| `timestamp` | float | When the message was transmitted |

### Methods

| Method | Description |
|--------|-------------|
| `from_state(state)` | Class method to reconstruct from serialized state |
| `get_state()` | Returns tuple of (from_client, content, timestamp) |
| `set_state(state)` | Updates message from serialized state |

## TCPFlow

A simplified representation of a complete TCP session.

### Constructor

```python
TCPFlow(
    client_conn: mitmproxy.connection.Client,
    server_conn: mitmproxy.connection.Server,
    live: bool = False
)
```

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `messages` | list[TCPMessage] | All messages transmitted over the connection |
| `type` | ClassVar[str] | `'tcp'` - identifies flow type |

### Methods

| Method | Description |
|--------|-------------|
| `get_state()` | Returns serialized flow state including all messages |
| `set_state(state)` | Restores flow from serialized state |

### Inherited from Flow

TCPFlow extends `mitmproxy.flow.Flow`, inheriting:
- `client_conn`, `server_conn` - Connection objects
- `error` - Error information
- `intercepted` - Interception state
- `kill()`, `resume()` - Flow control methods
- `copy()` - Deep copy
- `id`, `timestamp_created` - Metadata

## Usage Examples

### Modifying TCP Messages

```python
from mitmproxy import tcp

def tcp_message(flow: tcp.TCPFlow):
    message = flow.messages[-1]

    # Check direction
    if message.from_client:
        print("Client -> Server")
    else:
        print("Server -> Client")

    # Modify content
    message.content = message.content.replace(b"secret", b"REDACTED")
```

### Logging All TCP Traffic

```python
from mitmproxy import tcp
import logging

def tcp_message(flow: tcp.TCPFlow):
    message = flow.messages[-1]
    direction = ">>>" if message.from_client else "<<<"
    logging.info(f"{direction} {len(message.content)} bytes")
    logging.debug(f"Content: {message.content[:100]!r}")
```

### Blocking TCP Connections

```python
from mitmproxy import tcp

def tcp_start(flow: tcp.TCPFlow):
    # Block connections to specific ports
    if flow.server_conn.address[1] == 6667:  # IRC
        flow.kill()
```

### Injecting Data

```python
from mitmproxy import tcp, ctx

def tcp_message(flow: tcp.TCPFlow):
    message = flow.messages[-1]
    if b"AUTH" in message.content and message.from_client:
        # Inject additional data
        ctx.master.commands.call(
            "inject.tcp",
            flow,
            False,  # from_client=False means inject as server
            b"Welcome!\r\n"
        )
```
