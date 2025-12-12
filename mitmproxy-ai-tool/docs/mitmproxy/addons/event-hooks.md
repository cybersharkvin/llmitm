---
title: "Event Hooks"
weight: 2
url: api/events.html
aliases:
    - /addons-events/
---

# Event Hooks

Addons hook into mitmproxy's internal mechanisms through event hooks. These are
implemented on addons as methods with a set of well-known names. Many events
receive `Flow` objects as arguments - by modifying these objects, addons can
change traffic on the fly.

Example addon that adds a response header with a count:

```python
class AddHeader:
    def __init__(self):
        self.num = 0

    def response(self, flow):
        self.num = self.num + 1
        flow.response.headers["count"] = str(self.num)

addons = [AddHeader()]
```

## Lifecycle Events

### `load(loader: mitmproxy.addonmanager.Loader)`
Triggered when an addon first loads. Receives a Loader object for configuring options and commands.

### `running()`
Fired when the proxy reaches full operational status with all addons loaded and options configured.

### `configure(updated: set[str])`
Called during configuration changes. The `updated` parameter contains keys of all modified options. Also fires at startup with all options.

### `done()`
Invoked during addon removal or proxy shutdown. On shutdown, executes after event loop termination as the final addon event.

## Connection Events

### `client_connected(client: mitmproxy.connection.Client)`
A client establishes connection to mitmproxy. Multiple HTTP requests may use one connection. Setting `client.error` terminates the connection.

### `client_disconnected(client: mitmproxy.connection.Client)`
Client connection closes (client or mitmproxy initiated).

### `server_connect(data: mitmproxy.proxy.server_hooks.ServerConnectionHookData)`
Mitmproxy prepares to connect to a server. Setting `data.server.error` kills the connection.

### `server_connected(data: mitmproxy.proxy.server_hooks.ServerConnectionHookData)`
Mitmproxy successfully connects to a server.

### `server_disconnected(data: mitmproxy.proxy.server_hooks.ServerConnectionHookData)`
Server connection closes.

### `server_connect_error(data: mitmproxy.proxy.server_hooks.ServerConnectionHookData)`
Server connection fails. Each server connection receives either `server_connected` or this event, never both.

## HTTP Events

### `requestheaders(flow: mitmproxy.http.HTTPFlow)`
HTTP request headers successfully received; body remains empty.

### `request(flow: mitmproxy.http.HTTPFlow)`
Complete HTTP request processed. With streaming active, fires after entire body transmission. HTTP trailers remain modifiable.

### `responseheaders(flow: mitmproxy.http.HTTPFlow)`
HTTP response headers successfully received; body remains empty.

### `response(flow: mitmproxy.http.HTTPFlow)`
Complete HTTP response processed. With streaming active, fires after entire body transmission. HTTP trailers remain modifiable.

### `error(flow: mitmproxy.http.HTTPFlow)`
HTTP error occurs (invalid server responses, interrupted connections). Distinct from valid server error responses. Each flow receives either this or `response`, never both.

### `http_connect(flow: mitmproxy.http.HTTPFlow)`
HTTP CONNECT request received. Typically ignorable. Setting non-2xx response aborts connection. CONNECT requests don't generate typical HTTP handlers.

### `http_connect_upstream(flow: mitmproxy.http.HTTPFlow)`
HTTP CONNECT prepares transmission to upstream proxy. Useful for custom authentication headers.

### `http_connected(flow: mitmproxy.http.HTTPFlow)`
HTTP CONNECT succeeds.

### `http_connect_error(flow: mitmproxy.http.HTTPFlow)`
HTTP CONNECT fails (unreachable upstream server or proxy authentication required).

## DNS Events

### `dns_request(flow: mitmproxy.dns.DNSFlow)`
DNS query received.

### `dns_response(flow: mitmproxy.dns.DNSFlow)`
DNS response received or configured.

### `dns_error(flow: mitmproxy.dns.DNSFlow)`
DNS error occurs.

## TCP Events

### `tcp_start(flow: mitmproxy.tcp.TCPFlow)`
TCP connection initiates.

### `tcp_message(flow: mitmproxy.tcp.TCPFlow)`
TCP connection receives message. Most recent: `flow.messages[-1]`. Message is user-modifiable.

### `tcp_end(flow: mitmproxy.tcp.TCPFlow)`
TCP connection terminates.

### `tcp_error(flow: mitmproxy.tcp.TCPFlow)`
TCP error occurs. Each flow receives either this or `tcp_end`, never both.

## UDP Events

### `udp_start(flow: mitmproxy.udp.UDPFlow)`
UDP connection initiates.

### `udp_message(flow: mitmproxy.udp.UDPFlow)`
UDP connection receives message. Most recent: `flow.messages[-1]`. Message is user-modifiable.

### `udp_end(flow: mitmproxy.udp.UDPFlow)`
UDP connection terminates.

### `udp_error(flow: mitmproxy.udp.UDPFlow)`
UDP error occurs. Each flow receives either this or `udp_end`, never both.

## TLS Events

### `tls_clienthello(data: mitmproxy.tls.ClientHelloData)`
Mitmproxy receives TLS ClientHello message. Determines server connection necessity via `data.establish_server_tls_first`.

### `tls_start_client(data: mitmproxy.tls.TlsData)`
TLS negotiation between mitmproxy and client initiates.

### `tls_start_server(data: mitmproxy.tls.TlsData)`
TLS negotiation between mitmproxy and server initiates.

### `tls_established_client(data: mitmproxy.tls.TlsData)`
Client TLS handshake completes successfully.

### `tls_established_server(data: mitmproxy.tls.TlsData)`
Server TLS handshake completes successfully.

### `tls_failed_client(data: mitmproxy.tls.TlsData)`
Client TLS handshake fails.

### `tls_failed_server(data: mitmproxy.tls.TlsData)`
Server TLS handshake fails.

## WebSocket Events

### `websocket_start(flow: mitmproxy.http.HTTPFlow)`
WebSocket connection commences.

### `websocket_message(flow: mitmproxy.http.HTTPFlow)`
WebSocket message received from client or server. Most recent: `flow.messages[-1]`. Message is user-modifiable. Supports BINARY and TEXT frame types.

### `websocket_end(flow: mitmproxy.http.HTTPFlow)`
WebSocket connection ends. Check `flow.websocket.close_code` for termination reason.

## QUIC Events

### `quic_start_client(data: mitmproxy.proxy.layers.quic._hooks.QuicTlsData)`
TLS negotiation between mitmproxy and client over QUIC begins.

### `quic_start_server(data: mitmproxy.proxy.layers.quic._hooks.QuicTlsData)`
TLS negotiation between mitmproxy and server over QUIC begins.

## Advanced Events

### `next_layer(data: mitmproxy.proxy.layer.NextLayer)`
Network layers switch. Modify layer behavior via `data.layer`.

### `update(flows: Sequence[mitmproxy.flow.Flow])`
Called when one or more flow objects change, typically from different addons.
