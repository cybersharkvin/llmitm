---
title: "Options"
weight: 5
aliases:
  - /concepts-options/
---

# Options

The mitmproxy tools share a common [YAML](http://yaml.org/) configuration file
located at `~/.mitmproxy/config.yaml`. This file controls **options** - typed
values that determine the behaviour of mitmproxy. The options mechanism is very
comprehensive - in fact, options control all of mitmproxy's runtime behaviour.
Most command-line flags are simply aliases for underlying options, and
interactive settings changes made in **mitmproxy** and **mitmweb** just change
values in our runtime options store. This means that almost any facet of
mitmproxy's behaviour can be controlled through options.

The canonical reference for options is the `--options` flag, which is exposed by
each of the mitmproxy tools. Passing this flag will dump an annotated YAML
configuration to console, which includes all options and their default values.

The options mechanism is extensible - third-party addons can define options that
are treated exactly like mitmproxy's own. This means that addons can also be
configured through the central configuration file, and their options will appear
in the options editors in interactive tools.

## Tools

Both **mitmproxy** and **mitmweb** have built-in editors that let you view and
manipulate the complete configuration state of mitmproxy. Values you change
interactively have immediate effect in the running instance, and can be made
persistent by saving the settings out to a YAML configuration file (please see
the specific tool's interactive help for details on how to do this).

For all tools, options can be set directly by name using the `--set`
command-line option. Please see the command-line help (`--help`) for usage. Example:
```
mitmproxy --set anticomp=true
mitmweb --set ignore_hosts=example.com --set ignore_hosts=example.org 
```

## Available Options

This list might not reflect what is actually available in your current mitmproxy
environment. For an up-to-date list please use the `--options` flag for each of
the mitmproxy tools.

### Network & Connection Options
| Option | Type | Description |
|--------|------|-------------|
| `listen_host` | str | Address to bind proxy server(s) to |
| `listen_port` | int | Port for proxy server(s); defaults vary by mode |
| `connect_addr` | str | Local IP address for upstream connections |
| `tcp_timeout` | int | Timeout in seconds for inactive TCP connections (default: 600) |
| `rawtcp` | bool | Enable/disable raw TCP connections (default: True) |

### Proxy Modes
| Option | Type | Description |
|--------|------|-------------|
| `mode` | sequence | Proxy server types: regular, local, transparent, socks5, reverse, upstream, wireguard |
| `server` | bool | Start proxy server (default: True) |

### Request/Response Filtering & Modification
| Option | Type | Description |
|--------|------|-------------|
| `ignore_hosts` | sequence | Hosts to ignore without processing |
| `allow_hosts` | sequence | Opposite of ignore_hosts |
| `block_list` | sequence | Block matching requests with specified HTTP status codes |
| `block_global` | bool | Block public IP connections (default: True) |
| `block_private` | bool | Block private IP connections (default: False) |
| `map_remote` | sequence | Map remote resources to different URLs |
| `map_local` | sequence | Map remote resources to local files |
| `modify_body` | sequence | Replacement patterns for request/response bodies |
| `modify_headers` | sequence | Header modification patterns |

### Caching & Compression
| Option | Type | Description |
|--------|------|-------------|
| `anticache` | bool | Strip cache-related headers (default: False) |
| `anticomp` | bool | Request uncompressed data from servers (default: False) |
| `body_size_limit` | str | HTTP body size limit; supports k/m/g suffixes |

### SSL/TLS Configuration
| Option | Type | Description |
|--------|------|-------------|
| `certs` | sequence | SSL certificates in PEM format with optional domain patterns |
| `ciphers_client` | str | Ciphers for client connections (OpenSSL syntax) |
| `ciphers_server` | str | Ciphers for server connections (OpenSSL syntax) |
| `client_certs` | str | Client certificate file or directory |
| `request_client_cert` | bool | Request mutual TLS connection (default: False) |
| `key_size` | int | TLS key size for certificates (default: 2048) |
| `tls_version_client_min` | str | Minimum TLS version for clients (default: TLS1_2) |
| `tls_version_client_max` | str | Maximum TLS version for clients |
| `tls_version_server_min` | str | Minimum TLS version for servers (default: TLS1_2) |
| `tls_version_server_max` | str | Maximum TLS version for servers |
| `ssl_insecure` | bool | Skip upstream certificate verification (default: False) |
| `ssl_verify_upstream_trusted_ca` | str | Path to trusted CA certificate |
| `upstream_cert` | bool | Look up upstream certificate details (default: True) |

### Authentication
| Option | Type | Description |
|--------|------|-------------|
| `proxyauth` | str | Require proxy authentication; formats: "username:pass", "any", "@htpasswd_path", or LDAP |
| `upstream_auth` | str | HTTP Basic auth for upstream proxy; format: username:password |
| `stickycookie` | str | Cookie-based sticky auth filter |
| `stickyauth` | str | Header-based sticky auth filter |

### HTTP Protocol Options
| Option | Type | Description |
|--------|------|-------------|
| `http2` | bool | Enable HTTP/2 support (default: True) |
| `http2_ping_keepalive` | int | PING interval for idle HTTP/2 connections in seconds (default: 58) |
| `http3` | bool | Enable QUIC/HTTP/3 support (default: True) |
| `websocket` | bool | Enable WebSocket support (default: True) |
| `normalize_outbound_headers` | bool | Normalize HTTP/2 headers to lowercase (default: True) |
| `validate_inbound_headers` | bool | Validate incoming HTTP requests (default: True) |

### Request/Response Streaming
| Option | Type | Description |
|--------|------|-------------|
| `stream_large_bodies` | str | Stream bodies exceeding threshold; supports k/m/g suffixes |
| `store_streamed_bodies` | bool | Store streamed bodies in memory (default: False) |
| `content_view_lines_cutoff` | int | Flow content view line limit (default: 512) |

### Reverse/Upstream Proxy
| Option | Type | Description |
|--------|------|-------------|
| `keep_host_header` | bool | Keep original host header (default: False) |
| `keep_alt_svc_header` | bool | Keep Alt-Svc headers unchanged (default: False) |
| `connection_strategy` | str | When to establish server connections: eager or lazy (default: eager) |

### Flow Recording & Playback
| Option | Type | Description |
|--------|------|-------------|
| `rfile` | str | Read flows from file |
| `client_replay` | sequence | Replay client requests from saved file |
| `client_replay_concurrency` | int | Concurrency limit for client replay (default: 1) |
| `server_replay` | sequence | Replay server responses from saved file |
| `server_replay_refresh` | bool | Adjust date/expires headers in replayed responses (default: True) |
| `server_replay_reuse` | bool | Reuse flows without removing them (default: False) |
| `server_replay_extra` | str | Behavior for unmatched requests: forward, kill, or status code |
| `server_replay_ignore_content` | bool | Ignore request content in matching (default: False) |
| `server_replay_ignore_host` | bool | Ignore destination host (default: False) |
| `server_replay_ignore_port` | bool | Ignore destination port (default: False) |
| `server_replay_ignore_params` | sequence | Query parameters to ignore |
| `server_replay_ignore_payload_params` | sequence | Form parameters to ignore |
| `server_replay_use_headers` | sequence | Headers that must match for replay |

### File Operations
| Option | Type | Description |
|--------|------|-------------|
| `save_stream_file` | str | Stream flows to file as they arrive |
| `save_stream_filter` | str | Filter flows written to file |
| `hardump` | str | Save HAR file with flows on exit |
| `readfile_filter` | str | Read only matching flows |

### Interception
| Option | Type | Description |
|--------|------|-------------|
| `intercept` | str | Intercept filter expression |
| `intercept_active` | bool | Intercept toggle (default: False) |

### DNS Options
| Option | Type | Description |
|--------|------|-------------|
| `dns_name_servers` | sequence | Name servers for DNS lookups |
| `dns_use_hosts_file` | bool | Use system hosts file for DNS (default: True) |

### Scripting & Extensions
| Option | Type | Description |
|--------|------|-------------|
| `scripts` | sequence | Execute addon scripts |
| `confdir` | str | Configuration directory location (default: ~/.mitmproxy) |
| `cert_passphrase` | str | Passphrase for private key decryption |
| `protobuf_definitions` | str | Path to .proto file for Protobuf parsing |

### mitmdump-Specific Options
| Option | Type | Description |
|--------|------|-------------|
| `flow_detail` | int | Display detail level 0-4 (default: 1) |
| `dumper_default_contentview` | str | Default content view mode |
| `dumper_filter` | str | Limit flows displayed |
| `keepserving` | bool | Continue after playback/file read (default: False) |
| `termlog_verbosity` | str | Log verbosity: error, warn, info, alert, debug |

### mitmproxy Console-Specific Options
| Option | Type | Description |
|--------|------|-------------|
| `console_layout` | str | Layout mode: single, horizontal, vertical |
| `console_layout_headers` | bool | Show component headers (default: True) |
| `console_palette` | str | Color palette choice |
| `console_default_contentview` | str | Default content view mode |
| `console_eventlog_verbosity` | str | Event log verbosity |
| `console_flowlist_layout` | str | Flowlist layout: default, list, table |
| `console_focus_follow` | bool | Focus follows new flows (default: False) |
| `console_mouse` | bool | Mouse interaction enabled (default: True) |
| `command_history` | bool | Persist command history (default: True) |

### mitmweb-Specific Options
| Option | Type | Description |
|--------|------|-------------|
| `web_host` | str | Web UI host (default: 127.0.0.1) |
| `web_port` | int | Web UI port (default: 8081) |
| `web_password` | str | UI password (plaintext or argon2 hash) |
| `web_open_browser` | bool | Auto-launch browser (default: True) |
| `web_columns` | sequence | Columns to display in flow list |
| `web_static_viewer` | str | Path for static viewer output |
| `view_filter` | str | Limit view to matching flows |
| `view_order` | str | Flow sort order: time, method, url, size |
| `view_order_reversed` | bool | Reverse sort order (default: False) |

### Other Options
| Option | Type | Description |
|--------|------|-------------|
| `onboarding` | bool | Toggle onboarding app (default: True) |
| `onboarding_host` | str | Onboarding domain (default: mitm.it) |
| `showhost` | bool | Use Host header for display URLs (default: False) |
| `show_ignored_hosts` | bool | Record ignored flows in UI (default: False) |
| `tcp_hosts` | sequence | Generic TCP SSL proxy mode patterns |
| `udp_hosts` | sequence | Generic UDP SSL proxy mode patterns |
