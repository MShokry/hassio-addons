ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    git \
    ca-certificates \
    dumb-init \
    jq \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js using NodeSource repository (works for all architectures)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Verify installation
RUN node --version && npm --version

# Install ClawdBot globally
RUN npm install -g clawdbot@latest

# Create required directories for ClawdBot state management
RUN mkdir -p /data /data/workspace /data/agents /data/sessions

# Copy run script
COPY run.sh /
RUN chmod +x /run.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:18789/ || exit 1

ENTRYPOINT ["/sbin/dumb-init", "--"]
CMD ["/run.sh"]