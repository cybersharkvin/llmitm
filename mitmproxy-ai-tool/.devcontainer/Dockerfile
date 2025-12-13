FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Metadata
LABEL maintainer="llmitm"
LABEL description="Claude Code Bug Bounty Hunter with mitmproxy"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Node.js prerequisites
    curl \
    ca-certificates \
    gnupg \
    # Network tools (firewall)
    iptables \
    iproute2 \
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

# Create directories
RUN mkdir -p /home/vscode/captures \
             /home/vscode/certs \
             /home/vscode/.claude

# Copy firewall script
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh

# Set shell to zsh
RUN chsh -s /bin/zsh vscode

# Working directory
WORKDIR /workspace

# Default command
CMD ["sleep", "infinity"]
