FROM alpine:3.19

LABEL maintainer="llmitm"
LABEL description="Firewall sidecar for llmitm network isolation"

# Install networking tools
RUN apk add --no-cache \
    iptables \
    ip6tables \
    squid \
    bind-tools \
    curl \
    bash

# Create squid directories
RUN mkdir -p /var/cache/squid /var/log/squid \
    && chown -R squid:squid /var/cache/squid /var/log/squid

# Copy configuration and entrypoint
COPY squid.conf /etc/squid/squid.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose squid proxy port
EXPOSE 3128

ENTRYPOINT ["/entrypoint.sh"]
