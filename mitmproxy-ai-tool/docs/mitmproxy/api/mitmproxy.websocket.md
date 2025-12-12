---
title: "mitmproxy.websocket"
url: "api/mitmproxy/websocket.html"
menu: api
---

# mitmproxy.websocket API

The `mitmproxy.websocket` module provides classes for handling individual WebSocket messages and connection data. WebSocket connections are represented as HTTP flows with a `websocket` attribute.

## WebSocketMessage

A representation of a single WebSocket message exchanged between peers.

Fragmented messages are automatically reassembled. All content is stored as bytes to avoid type confusion; text can be accessed via the `text` property.

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `from_client` | bool | True if message originated from client |
| `type` | Opcode | Message type (TEXT or BINARY frames only) |
| `content` | bytes | Message payload as bytes |
| `timestamp` | float | When the message was received or created |
| `dropped` | bool | Whether message was blocked from forwarding |
| `injected` | bool | Whether message was injected rather than from peer |

### Properties

| Property | Description |
|----------|-------------|
| `is_text` | True for TEXT frames, False for BINARY frames |
| `text` | Decodes/encodes content as string (TEXT frames only) |

### Methods

| Method | Description |
|--------|-------------|
| `drop()` | Prevents message forwarding to the peer |
| `from_state(state)` | Reconstructs message from serialized state |
| `get_state()` | Returns message as state tuple |
| `set_state(state)` | Updates message from state tuple |

## WebSocketData

A container for all WebSocket connection metadata and messages. Accessed as `flow.websocket` on HTTP flows.

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `messages` | list[WebSocketMessage] | All messages transferred |
| `closed_by_client` | bool \| None | True if client closed, False if server, None if active |
| `close_code` | int \| None | RFC 6455 close code |
| `close_reason` | str \| None | RFC 6455 close reason |
| `timestamp_end` | float \| None | When connection closed |

## Usage Examples

### Processing WebSocket Messages

```python
from mitmproxy import http

def websocket_message(flow: http.HTTPFlow):
    assert flow.websocket is not None
    message = flow.websocket.messages[-1]

    direction = "Client" if message.from_client else "Server"
    print(f"{direction}: {message.content!r}")
```

### Modifying Text Messages

```python
from mitmproxy import http

def websocket_message(flow: http.HTTPFlow):
    message = flow.websocket.messages[-1]

    if message.is_text:
        # Access and modify text content
        text = message.text
        message.text = text.replace("secret", "REDACTED")
```

### Dropping Messages

```python
from mitmproxy import http

def websocket_message(flow: http.HTTPFlow):
    message = flow.websocket.messages[-1]

    # Drop messages containing sensitive data
    if b"password" in message.content:
        message.drop()
```

### Injecting Messages

```python
from mitmproxy import http, ctx

def websocket_message(flow: http.HTTPFlow):
    message = flow.websocket.messages[-1]

    if message.is_text and "ping" in message.text:
        # Inject a response
        ctx.master.commands.call(
            "inject.websocket",
            flow,
            False,  # from_client=False means inject as server
            b'{"type": "pong"}'
        )
```

### Checking Connection State

```python
from mitmproxy import http

def websocket_end(flow: http.HTTPFlow):
    ws = flow.websocket

    if ws.closed_by_client:
        print("Client closed the connection")
    else:
        print("Server closed the connection")

    if ws.close_code:
        print(f"Close code: {ws.close_code}")
        print(f"Close reason: {ws.close_reason}")
```

### Working with Binary Data

```python
from mitmproxy import http
import struct

def websocket_message(flow: http.HTTPFlow):
    message = flow.websocket.messages[-1]

    if not message.is_text:
        # Handle binary protocol
        if len(message.content) >= 4:
            msg_type = struct.unpack(">I", message.content[:4])[0]
            print(f"Binary message type: {msg_type}")
```
