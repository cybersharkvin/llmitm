---
title: "mitmproxy.dns"
url: "api/mitmproxy/dns.html"
menu: api
---

# mitmproxy.dns API

The `mitmproxy.dns` module provides DNS message handling and flow representation for mitmproxy, including classes for DNS queries, responses, and resource records.

## Question

A DNS question with domain name and query parameters.

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | str | The domain name being queried |
| `type` | int | DNS record type (A, AAAA, CNAME, etc.) |
| `class_` | int | DNS class (typically IN for Internet) |

### Methods

| Method | Description |
|--------|-------------|
| `to_json()` | Converts question to JSON |
| `from_json(data)` | Reconstructs question from JSON |

## ResourceRecord

Represents a DNS resource record with flexible data handling.

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | str | Resource record name |
| `type` | int | Record type identifier |
| `class_` | int | DNS class |
| `ttl` | int | Time to live (default: 60 seconds) |
| `data` | bytes | Raw record data |

### Properties

| Property | Description |
|----------|-------------|
| `text` | Decode/encode data as UTF-8 text |
| `ipv4_address` | Parse/set IPv4 address |
| `ipv6_address` | Parse/set IPv6 address |
| `domain_name` | Parse/set domain name |
| `https_alpn` | HTTPS ALPN protocols |
| `https_ech` | HTTPS Encrypted Client Hello (base64) |

### Factory Methods

| Method | Description |
|--------|-------------|
| `A(name, ip, *, ttl)` | Create IPv4 record |
| `AAAA(name, ip, *, ttl)` | Create IPv6 record |
| `CNAME(alias, canonical, *, ttl)` | Create CNAME record |
| `PTR(inaddr, ptr, *, ttl)` | Create PTR record |
| `TXT(name, text, *, ttl)` | Create TXT record |
| `HTTPS(name, record, ttl)` | Create HTTPS record |

## DNSMessage

Complete DNS protocol message with flags and multiple record sections.

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `id` | int | Message identifier |
| `query` | bool | True if this is a query (vs response) |
| `op_code` | int | Operation code |
| `authoritative_answer` | bool | Server authority indicator |
| `truncation` | bool | Message truncation flag |
| `recursion_desired` | bool | Client recursion request |
| `recursion_available` | bool | Server recursion support |
| `response_code` | int | Response status code |
| `questions` | list[Question] | Query questions section |
| `answers` | list[ResourceRecord] | Answer records |
| `authorities` | list[ResourceRecord] | Authority records |
| `additionals` | list[ResourceRecord] | Additional records |
| `timestamp` | float \| None | Message send/receive time |

### Properties

| Property | Description |
|----------|-------------|
| `content` | Packed message bytes |
| `question` | First question (DNS typically has one) |
| `size` | Cumulative data size of all records |
| `packed` | Network-serialized message |

### Methods

| Method | Description |
|--------|-------------|
| `fail(response_code)` | Create error response |
| `succeed(answers)` | Create successful response |
| `unpack(buffer, timestamp)` | Parse complete message |
| `copy()` | Deep copy with randomized ID |

## DNSFlow

Represents a complete DNS transaction (query and optional response).

### Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `request` | DNSMessage | The DNS query message |
| `response` | DNSMessage \| None | The DNS response (if received) |
| `type` | ClassVar[str] | `'dns'` - identifies flow type |

## Usage Examples

### Spoofing DNS Responses

```python
from mitmproxy import dns
import ipaddress

def dns_request(flow: dns.DNSFlow) -> None:
    q = flow.request.question
    if q and q.name == "example.com":
        # Return custom IP
        flow.response = flow.request.succeed([
            dns.ResourceRecord.A("example.com", "127.0.0.1", ttl=300)
        ])
```

### Blocking DNS Queries

```python
from mitmproxy import dns

def dns_request(flow: dns.DNSFlow) -> None:
    q = flow.request.question
    if q and "malware" in q.name:
        # Return NXDOMAIN
        flow.response = flow.request.fail(3)  # NXDOMAIN
```

### Logging DNS Queries

```python
from mitmproxy import dns
import logging

def dns_request(flow: dns.DNSFlow) -> None:
    q = flow.request.question
    if q:
        logging.info(f"DNS query: {q.name} (type {q.type})")

def dns_response(flow: dns.DNSFlow) -> None:
    if flow.response:
        for answer in flow.response.answers:
            if hasattr(answer, 'ipv4_address'):
                logging.info(f"  -> {answer.ipv4_address}")
```

### Rewriting DNS Responses

```python
from mitmproxy import dns

def dns_response(flow: dns.DNSFlow) -> None:
    if flow.response:
        for answer in flow.response.answers:
            # Redirect all A records to localhost
            if answer.type == 1:  # A record
                answer.ipv4_address = "127.0.0.1"
```

### IPv6 Spoofing

```python
from mitmproxy import dns
import ipaddress

def dns_request(flow: dns.DNSFlow) -> None:
    q = flow.request.question
    if q and q.type == 28:  # AAAA record
        if q.name == "example.com":
            flow.response = flow.request.succeed([
                dns.ResourceRecord.AAAA("example.com", "::1", ttl=300)
            ])
```
