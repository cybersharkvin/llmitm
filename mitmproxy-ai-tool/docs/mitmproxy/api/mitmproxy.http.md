---
title: "mitmproxy.http"
url: "api/mitmproxy/http.html"
menu: api
---

# mitmproxy.http API

The `mitmproxy.http` module provides core classes for handling HTTP traffic interception and manipulation.

## Headers

A specialized dictionary-like class for managing HTTP headers with case-insensitive access.

**Key Features:**
- Case-insensitive key lookups
- Multiple headers are folded into a single header as per RFC 7230
- Supports creating headers from keyword arguments or byte tuples

**Methods:**
- `get_all(name)` - Returns unfolded headers (useful for Set-Cookie, Cookie)
- `set_all(name, values)` - Explicitly set multiple headers
- `insert(index, key, value)` - Insert header at specific position
- `items(multi=False)` - Return header items with optional multi-header support

## Message

Base class for Request and Response objects providing common HTTP message handling.

**Key Properties:**
| Property | Description |
|----------|-------------|
| `http_version` | HTTP version string (e.g., "HTTP/1.1") |
| `headers` | The HTTP headers collection |
| `trailers` | HTTP trailer headers |
| `raw_content` | Potentially compressed message body |
| `content` | Uncompressed message body as bytes |
| `text` | Uncompressed and decoded message body as text |
| `timestamp_start` | When headers were received |
| `timestamp_end` | When last byte was received |

**Key Methods:**
| Method | Description |
|--------|-------------|
| `set_content(value)` | Set body with automatic encoding handling |
| `get_content(strict=True)` | Retrieve potentially compressed content |
| `set_text(text)` | Set body with automatic charset encoding |
| `get_text(strict=True)` | Retrieve decoded text with fallback behavior |
| `decode(strict=True)` | Decompress body and remove Content-Encoding header |
| `encode(encoding)` | Compress body with specified encoding |
| `json(**kwargs)` | Parse body as JSON |

**HTTP Version Detection:**
- `is_http10`, `is_http11`, `is_http2`, `is_http3`

## Request

Represents an HTTP request with full URL and method information.

**Key Properties:**
| Property | Description |
|----------|-------------|
| `method` | HTTP method (GET, POST, etc.) |
| `scheme` | Protocol scheme (http/https) |
| `authority` | Request authority information |
| `host` | Target server hostname or IP |
| `port` | Target server port |
| `path` | Request path with query string |
| `url` | Full constructed URL |
| `pretty_host` | Host from Host header (preferred for display) |
| `pretty_url` | URL using pretty_host |
| `query` | Query parameters as mutable MultiDictView |
| `cookies` | Request cookies as mutable MultiDictView |
| `path_components` | URL path segments as tuple |
| `urlencoded_form` | URL-encoded form data |
| `multipart_form` | Multipart form data |

**Key Methods:**
| Method | Description |
|--------|-------------|
| `make(method, url, content="", headers=())` | Create request via simplified API |
| `anticache()` | Remove cache-related headers |
| `anticomp()` | Set Accept-Encoding to identity |
| `constrain_encoding()` | Limit to decodable encodings |

## Response

Represents an HTTP response with status and reason information.

**Key Properties:**
| Property | Description |
|----------|-------------|
| `status_code` | HTTP status code (e.g., 200) |
| `reason` | HTTP reason phrase (e.g., "OK") |
| `cookies` | Response cookies with attributes as MultiDictView |

**Key Methods:**
| Method | Description |
|--------|-------------|
| `make(status_code=200, content=b"", headers=())` | Create response via simplified API |
| `refresh(now=None)` | Refresh response for replay by updating date/expires headers |

## HTTPFlow

Represents a complete HTTP transaction.

**Attributes:**
| Attribute | Description |
|-----------|-------------|
| `request` | The client's HTTP request |
| `response` | The server's HTTP response (optional) |
| `error` | Connection or protocol error (optional) |
| `websocket` | WebSocket data if connection upgraded |
| `timestamp_start` | Transaction start time |

**Methods:**
| Method | Description |
|--------|-------------|
| `copy()` | Create independent copy of flow |

## Usage Examples

### Modifying Headers

```python
def request(flow):
    flow.request.headers["X-Custom"] = "value"
    del flow.request.headers["Cookie"]
```

### Reading/Writing Body

```python
def response(flow):
    # Read as text
    body = flow.response.text

    # Modify and write back
    flow.response.text = body.replace("old", "new")
```

### Query Parameters

```python
def request(flow):
    # Read query param
    user_id = flow.request.query.get("id")

    # Modify query param
    flow.request.query["debug"] = "true"
```

### Creating Responses

```python
def request(flow):
    flow.response = http.Response.make(
        200,
        b"Custom response body",
        {"Content-Type": "text/plain"}
    )
```

### JSON Handling

```python
def response(flow):
    if "application/json" in flow.response.headers.get("content-type", ""):
        data = flow.response.json()
        data["injected"] = True
        flow.response.text = json.dumps(data)
```
