---
title: "Examples"
weight: 6
aliases:
  - /addons-examples/
---

# Addon Examples

mitmproxy provides a comprehensive collection of addon examples demonstrating various scripting capabilities.

## HTTP Examples

### Redirect Requests
Route HTTP requests to alternate servers:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if flow.request.pretty_host == "example.org":
        flow.request.host = "mitmproxy.org"
```

### Add Response Header
Add an HTTP header to each response:

```python
class AddHeader:
    def __init__(self):
        self.num = 0

    def response(self, flow):
        self.num = self.num + 1
        flow.response.headers["count"] = str(self.num)

addons = [AddHeader()]
```

### Reply From Proxy
Generate responses directly from proxy without contacting upstream servers:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if flow.request.pretty_url == "http://example.com/path":
        flow.response = http.Response.make(
            200,
            b"Hello World",
            {"Content-Type": "text/html"},
        )
```

### Modify Query String
Alter URL query parameters:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    flow.request.query["mitmproxy"] = "rocks"
```

### Modify Form Data
Modify form submissions:

```python
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    if flow.request.urlencoded_form:
        flow.request.urlencoded_form["mitmproxy"] = "rocks"
    else:
        flow.request.urlencoded_form = [("foo", "bar")]
```

### Stream Modify
Modify streamed response content:

```python
def modify(data: bytes) -> bytes:
    return data.replace(b"foo", b"bar")

def responseheaders(flow):
    flow.response.stream = modify
```

## WebSocket Examples

### Simple WebSocket
Process individual WebSocket messages:

```python
import re
from mitmproxy import http

def websocket_message(flow: http.HTTPFlow):
    assert flow.websocket is not None
    message = flow.websocket.messages[-1]

    if message.from_client:
        print(f"Client sent: {message.content!r}")

    message.content = re.sub(rb"^Hello", b"HAPPY", message.content)

    if b"FOOBAR" in message.content:
        message.drop()
```

### Inject WebSocket Message
Inject messages into active WebSocket connections:

```python
from mitmproxy import ctx, http

def websocket_message(flow: http.HTTPFlow):
    last_message = flow.websocket.messages[-1]
    if last_message.is_text and "secret" in last_message.text:
        last_message.drop()
        ctx.master.commands.call(
            "inject.websocket", flow, last_message.from_client, b"ssssssh"
        )
```

## TCP/DNS Examples

### TCP Simple
Modify TCP stream content:

```python
from mitmproxy import tcp

def tcp_message(flow: tcp.TCPFlow):
    message = flow.messages[-1]
    message.content = message.content.replace(b"foo", b"bar")
```

### DNS Spoof
Spoof DNS responses:

```python
import ipaddress
from mitmproxy import dns

def dns_request(flow: dns.DNSFlow) -> None:
    q = flow.request.question
    if q and q.type == dns.types.AAAA:
        if q.name == "example.com":
            flow.response = flow.request.succeed([
                dns.ResourceRecord(
                    name="example.com",
                    type=dns.types.AAAA,
                    data=ipaddress.ip_address("::1").packed,
                )
            ])
```

## Configuration Examples

### Custom Options
Add custom mitmproxy options:

```python
from mitmproxy import ctx

class AddHeader:
    def load(self, loader):
        loader.add_option(
            name="addheader",
            typespec=bool,
            default=False,
            help="Add a count header to responses",
        )

    def response(self, flow):
        if ctx.options.addheader:
            self.num = self.num + 1
            flow.response.headers["count"] = str(self.num)

addons = [AddHeader()]
```

Usage: `mitmproxy -s options-simple.py --set addheader=true`

### Custom Commands
Add custom commands to prompt:

```python
from mitmproxy import command
import logging

class MyAddon:
    def __init__(self):
        self.num = 0

    @command.command("myaddon.inc")
    def inc(self) -> None:
        self.num += 1
        logging.info(f"num = {self.num}")

addons = [MyAddon()]
```

## Flow Management Examples

### Duplicate and Replay
Duplicate, modify, and replay requests:

```python
from mitmproxy import ctx

def request(flow):
    if flow.is_replay == "request":
        return
    flow = flow.copy()
    if "view" in ctx.master.addons:
        ctx.master.commands.call("view.flows.duplicate", [flow])
    flow.request.path = "/changed"
    ctx.master.commands.call("replay.client", [flow])
```

### Write Flow File
Generate mitmproxy dump files programmatically:

```python
import random
from mitmproxy import http, io
from typing import BinaryIO

class Writer:
    def __init__(self) -> None:
        self.f: BinaryIO = open("out.mitm", "wb")
        self.w = io.FlowWriter(self.f)

    def response(self, flow: http.HTTPFlow) -> None:
        if random.choice([True, False]):
            self.w.add(flow)

    def done(self):
        self.f.close()

addons = [Writer()]
```

### Read Saved Flows
Parse saved flow dump files:

```python
import sys
from mitmproxy import io, http

with open(sys.argv[1], "rb") as logfile:
    freader = io.FlowReader(logfile)
    for f in freader.stream():
        if isinstance(f, http.HTTPFlow):
            print(f.request.host)
```

## Advanced Examples

### Non-blocking Hooks
Implement async/concurrent event hooks:

```python
import asyncio
import logging

async def request(flow):
    logging.info(f"handle request: {flow.request.host}{flow.request.path}")
    await asyncio.sleep(5)
```

Or with threading:

```python
from mitmproxy.script import concurrent
import time

@concurrent
def request(flow):
    time.sleep(5)
```

### Filter Flows
Apply mitmproxy filter patterns in scripts:

```python
from mitmproxy import flowfilter, ctx, http
from mitmproxy.addonmanager import Loader

class Filter:
    def load(self, loader: Loader):
        loader.add_option("flowfilter", str, "", "Check that flow matches filter.")

    def configure(self, updates):
        if "flowfilter" in updates:
            self.filter = flowfilter.parse(ctx.options.flowfilter)

    def response(self, flow: http.HTTPFlow) -> None:
        if flowfilter.match(self.filter, flow):
            print("Flow matches filter!")

addons = [Filter()]
```

### Shutdown Proxy
Gracefully shut down mitmproxy:

```python
from mitmproxy import ctx, http

def request(flow: http.HTTPFlow) -> None:
    if flow.request.pretty_url == "http://example.com/shutdown":
        ctx.master.shutdown()
```

### Host WSGI App
Host Flask/WSGI applications within mitmproxy:

```python
from flask import Flask
from mitmproxy.addons import asgiapp

app = Flask("proxapp")

@app.route("/")
def hello_world() -> str:
    return "Hello World!"

addons = [
    asgiapp.WSGIApp(app, "example.com", 80),
]
```
