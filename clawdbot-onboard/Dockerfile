ARG BUILD_FROM
ARG BUILD_ARCH
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install system dependencies
RUN \
    apk add --no-cache \
        curl \
        ca-certificates \
        jq \
        bash \
        xz \
        tar \
        python3 \
        make \
        g++ \
        git \
        nodejs \
        npm

# Configure npm for Alpine/musl compatibility
RUN \
    npm config set ignore-scripts false \
    && npm config set audit false \
    && npm config set fund false

# Install ClawdBot globally
RUN \
    npm install -g clawdbot@latest \
    && clawdbot --version || echo "ClawdBot installed"

# Create directories
RUN mkdir -p /root/.clawdbot /config /data

# Copy run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /root/.clawdbot

# Expose ports (Gateway and Canvas/Onboarding)
EXPOSE 18789 18793

# Run the add-on
CMD ["/run.sh"]