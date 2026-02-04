# LLMitM v1.5
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl ca-certificates gnupg \
    python3 python3-pip \
    netcat-openbsd dnsutils \
    git jq bubblewrap socat \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Claude Code + mitmproxy
RUN npm install -g @anthropic-ai/claude-code @anthropic-ai/sandbox-runtime \
    && pip3 install --no-cache-dir mitmproxy

# Non-root user
RUN useradd -m -s /bin/bash -u 1000 llmitm
USER llmitm
WORKDIR /workspace
CMD ["bash"]
