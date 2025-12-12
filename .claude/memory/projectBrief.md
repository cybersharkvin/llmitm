# Project Brief

## Project Goal

Build an "LLM-in-the-middle proxy" system that enables Claude (or other LLMs) to directly operate mitmdump from the command line for automated security testing and bug bounty hunting. The project transforms mitmdump's CLI into a powerful LLM-operated tool, allowing the AI to capture, analyze, mutate, and replay HTTP/HTTPS traffic autonomously while hunting for vulnerabilities.

## Core Requirements

- **CLI-First Operation**: All functionality accessible via mitmdump commands that an LLM can execute through bash - no GUI dependencies
- **Capture & Analysis**: Ability to capture live traffic, filter by domain/method/content, and analyze saved flows with varying verbosity levels
- **Traffic Mutation**: Modify headers, bodies, and parameters using mitmdump's `-H` and `-B` flags for security testing (IDOR, privilege escalation, injection)
- **Replay Capabilities**: Client replay (`-C`) to re-send modified requests and observe server responses
- **Python Addons**: Custom mitmproxy addon scripts for automated vulnerability detection (credential leaks, JWT capture, sensitive data exposure)
- **Filter Mastery**: Leverage mitmproxy's filter expressions (`~d`, `~u`, `~m`, `~bq`, `~bs`, `~c`, etc.) for precise traffic selection

## Success Criteria

- LLM can autonomously execute the capture→analyze→mutate→replay→observe workflow
- Effective identification of common vulnerabilities: IDOR, auth bypass, privilege escalation, sensitive data exposure
- Clean integration with bug bounty methodology (evidence collection, reproducible findings)
- Python addons for automated detection of credentials, tokens, and API keys in traffic

## Out of Scope

- GUI interfaces (mitmproxy interactive mode, mitmweb)
- Mobile certificate pinning bypass (android-unpinner) - separate tooling
- Transparent proxy network gateway configuration
- Full Burp Suite replacement - this complements, not replaces

## User Stories

**Bug Bounty Hunter**: "I want Claude to intercept my browsing traffic, identify interesting API endpoints, automatically test for IDOR and auth bypass vulnerabilities, and generate evidence for my reports."

**Security Researcher**: "I need an AI assistant that can analyze captured traffic files, identify patterns indicating vulnerabilities, mutate requests to test hypotheses, and systematically explore attack surfaces."

---

**Update Frequency**: Rarely (only when scope genuinely changes)
