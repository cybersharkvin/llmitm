"""
Pydantic models for SNI proxy configuration.
"""
from __future__ import annotations

import os
from enum import Enum
from typing import List

from pydantic import BaseModel, Field


class FilterAction(str, Enum):
    """Action to take for traffic."""

    ALLOW = "allow"
    DENY = "deny"


class DomainRule(BaseModel):
    """A single domain allowlist rule."""

    pattern: str = Field(..., description="Domain pattern (e.g., 'example.com')")
    include_subdomains: bool = Field(default=True)

    def matches(self, host: str) -> bool:
        """Check if host matches this rule."""
        host = host.lower().strip()
        pattern = self.pattern.lower().strip()

        if self.include_subdomains:
            return host == pattern or host.endswith(f".{pattern}")
        return host == pattern


class ProxyConfig(BaseModel):
    """Configuration for the SNI proxy."""

    allowlist: List[DomainRule] = Field(default_factory=list)
    default_action: FilterAction = Field(default=FilterAction.DENY)
    log_blocked: bool = Field(default=True)
    log_allowed: bool = Field(default=False)
    http_port: int = Field(default=8080)
    https_port: int = Field(default=8443)

    # Always-allowed domains (Claude API, etc.)
    system_domains: List[str] = Field(
        default=[
            "anthropic.com",
            "claude.ai",
            "sentry.io",
        ]
    )

    def is_allowed(self, host: str) -> bool:
        """Check if host is in allowlist."""
        host = host.lower().strip()

        # Check system domains first
        for domain in self.system_domains:
            if host == domain or host.endswith(f".{domain}"):
                return True

        # Check user allowlist
        for rule in self.allowlist:
            if rule.matches(host):
                return True

        return self.default_action == FilterAction.ALLOW

    @classmethod
    def from_env(cls) -> ProxyConfig:
        """Load config from environment variables."""
        config = cls()

        # Load TARGET_DOMAINS from env
        target_domains = os.environ.get("TARGET_DOMAINS", "")
        if target_domains:
            for domain in target_domains.split(","):
                domain = domain.strip()
                if domain:
                    config.allowlist.append(DomainRule(pattern=domain))

        return config
