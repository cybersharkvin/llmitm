FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Metadata
LABEL maintainer="llmitm"
LABEL description="Claude Code Bug Bounty Hunter with mitmproxy"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
# NOTE: No iptables - network isolation handled by firewall sidecar
RUN apt-get update && apt-get install -y \
    # Node.js prerequisites
    curl \
    ca-certificates \
    gnupg \
    # Network debugging (no admin tools)
    netcat-openbsd \
    dnsutils \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # Development tools
    git \
    zsh \
    fzf \
    jq \
    vim \
    nano \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Install mitmproxy via pip (latest stable)
RUN pip3 install --no-cache-dir mitmproxy

# Set shell to zsh
RUN chsh -s /bin/zsh vscode

# Switch to non-root user (vscode user is created by base image)
# Required for Claude Code --dangerously-skip-permissions flag (Claude Code 2.0.70+ forbids this with root)
USER vscode

# Working directory
WORKDIR /workspace

# Note: Let Claude Code create ~/.claude/ on first run with correct permissions
# Project's .claude/ is mounted at /workspace/.claude/ from mitmproxy-ai-tool/

# Default command
CMD ["sleep", "infinity"]
