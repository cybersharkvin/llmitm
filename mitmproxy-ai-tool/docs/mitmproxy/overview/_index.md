---
title: Overview
---

# Overview

Getting started with mitmproxy installation, configuration, and core features.

## In This Section

| Document | Description |
|----------|-------------|
| [Getting Started](getting-started.md) | Quick start guide for first-time users |
| [Installation](installation.md) | Installation methods for various platforms |
| [Features](features.md) | Feature overview: replay, blocklist, map local/remote, modify headers/body |

## Quick Start

```bash
# Install mitmproxy
pip install mitmproxy

# Start proxy on port 8080
mitmdump -p 8080

# Start with traffic capture
mitmdump -w traffic.flow
```