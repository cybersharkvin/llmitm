---
title: "mitmproxy.flow"
url: "api/mitmproxy/flow.html"
menu: api
---

# mitmproxy.flow API

The `mitmproxy.flow` module provides base classes for representing network flows—collections of protocol messages like HTTP request/response pairs or TCP messages.

## Error

A dataclass representing connection and protocol errors (distinct from protocol-level responses).

**Attributes:**
| Attribute | Description |
|-----------|-------------|
| `msg` | Error description message |
| `timestamp` | Unix timestamp when error occurred (defaults to current time) |
| `KILLED_MESSAGE` | Constant: `"Connection killed."` |

**Methods:**
- `__str__()` — Returns the error message
- `__repr__()` — Returns the error message

## Flow

Base class for all network flows (HTTP, TCP, UDP, DNS).

**Attributes:**
| Attribute | Type | Description |
|-----------|------|-------------|
| `client_conn` | `connection.Client` | The connecting client |
| `server_conn` | `connection.Server` | The connected server |
| `error` | `Error \| None` | Any connection/protocol error |
| `intercepted` | `bool` | Whether flow is paused awaiting user action |
| `marked` | `str` | User-set marker (character or emoji name) |
| `is_replay` | `str \| None` | Either `"request"` or `"response"` if replayed |
| `live` | `bool` | True for active connections; False for completed/loaded flows |
| `timestamp_created` | `float` | Creation timestamp (unchanged on replay) |
| `id` | `str` | Unique flow identifier |
| `comment` | `str` | User comment |
| `type` | `ClassVar[str]` | Flow type (`"http"`, `"tcp"`, `"udp"`, etc.) |

**Methods:**
| Method | Description |
|--------|-------------|
| `copy()` | Create a copy (sets `live=False`) |
| `modified()` | Check if user modified the flow |
| `backup()` | Save state for restoration |
| `revert()` | Restore from backup |
| `kill()` | Prevent forwarding to destination |
| `intercept()` | Pause flow processing |
| `resume()` | Continue after interception |
| `wait_for_resume()` | Async wait for resume signal |
| `get_state()` | Serialize to dictionary |
| `set_state(state)` | Restore from dictionary |
| `from_state(state)` | Class method to reconstruct from state |

**Properties:**
| Property | Description |
|----------|-------------|
| `killable` | Read-only; True if flow can be killed |
| `timestamp_start` | Read-only; flow start time |

## Flow Types

### HTTPFlow
HTTP request/response pairs. See `mitmproxy.http.HTTPFlow`.

### TCPFlow
Raw TCP message streams.

```python
from mitmproxy import tcp

def tcp_message(flow: tcp.TCPFlow):
    message = flow.messages[-1]
    print(f"Direction: {'client' if message.from_client else 'server'}")
    print(f"Content: {message.content}")
```

### UDPFlow
UDP datagram streams.

```python
from mitmproxy import udp

def udp_message(flow: udp.UDPFlow):
    message = flow.messages[-1]
    message.content = message.content.replace(b"old", b"new")
```

### DNSFlow
DNS query/response pairs.

```python
from mitmproxy import dns

def dns_request(flow: dns.DNSFlow):
    if flow.request.question:
        print(f"Query: {flow.request.question.name}")
```

## Usage Examples

### Killing a Flow

```python
def request(flow):
    if "blocked.com" in flow.request.host:
        flow.kill()
```

### Intercepting for Manual Review

```python
def request(flow):
    if "sensitive" in flow.request.path:
        flow.intercept()
```

### Checking if Replayed

```python
def request(flow):
    if flow.is_replay == "request":
        print("This is a replayed request")
        return  # Skip processing
```

### Working with Flow State

```python
def request(flow):
    # Save current state
    flow.backup()

    # Make changes
    flow.request.headers["Modified"] = "true"

    # Restore original if needed
    # flow.revert()
```

### Copying Flows

```python
from mitmproxy import ctx

def request(flow):
    # Create a copy for replay
    flow_copy = flow.copy()
    flow_copy.request.path = "/modified"
    ctx.master.commands.call("replay.client", [flow_copy])
```
