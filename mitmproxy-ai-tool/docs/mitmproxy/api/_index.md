---
title: "API Reference"
---

# API Reference

Python API documentation for mitmproxy's core data structures. Use these classes in addons to inspect and manipulate traffic.

## In This Section

| Document | Description |
|----------|-------------|
| [mitmproxy.http](mitmproxy.http.md) | HTTP traffic: `Request`, `Response`, `Headers`, `Message` classes |
| [mitmproxy.flow](mitmproxy.flow.md) | Flow objects representing complete request/response pairs |
| [mitmproxy.connection](mitmproxy.connection.md) | Client and server connection information |
| [mitmproxy.tcp](mitmproxy.tcp.md) | Raw TCP flow handling |
| [mitmproxy.websocket](mitmproxy.websocket.md) | WebSocket message handling |
| [mitmproxy.dns](mitmproxy.dns.md) | DNS query and response handling |

## Common API Usage

Access request/response in addon hooks:
```python
def response(self, flow):
    # Request data
    flow.request.url          # Full URL
    flow.request.method       # HTTP method
    flow.request.headers      # Headers dict
    flow.request.content      # Body bytes

    # Response data
    flow.response.status_code # HTTP status
    flow.response.headers     # Response headers
    flow.response.text        # Body as string
    flow.response.json()      # Parse JSON body
```

