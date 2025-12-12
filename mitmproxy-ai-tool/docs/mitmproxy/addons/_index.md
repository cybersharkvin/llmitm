---
title: "Addon Development"
---

# Addon Development

Python addons extend mitmproxy's functionality by hooking into traffic events. Write custom scripts to analyze, modify, or automate HTTP/HTTPS traffic handling.

## In This Section

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Introduction to addon architecture and concepts |
| [Event Hooks](event-hooks.md) | All available event hooks: `request`, `response`, `load`, `configure`, etc. |
| [Options](options.md) | Defining custom addon options |
| [Commands](commands.md) | Creating addon commands callable from mitmproxy |
| [Content Views](contentviews.md) | Custom content rendering for specific data formats |
| [Examples](examples.md) | Practical addon code examples |
| [API Changelog](api-changelog.md) | Breaking changes and migration notes |

## Key Usage for LLM Operation

Load addons with mitmdump:
```bash
mitmdump -s my_addon.py
```

Common addon patterns:
- **Traffic analysis**: Hook `response` to inspect server responses
- **Request modification**: Hook `request` to add/modify headers or body
- **Credential capture**: Hook events to log tokens, cookies, API keys 