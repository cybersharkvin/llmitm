FROM python:3.11-alpine

LABEL maintainer="llmitm"
LABEL description="Firewall sidecar with SNI-based transparent proxy"

# Install iptables and network tools
RUN apk add --no-cache \
    iptables \
    ip6tables \
    dnsmasq \
    bind-tools \
    curl \
    bash

# Install Python dependencies (minimal - just pydantic)
COPY requirements.txt /etc/proxy/
RUN pip install --no-cache-dir -r /etc/proxy/requirements.txt

# Copy proxy code
COPY proxy/ /etc/proxy/

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose proxy ports
EXPOSE 8080 8443

ENTRYPOINT ["/entrypoint.sh"]
