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

# Install Node.js 22 (required by ClawdBot)
# Using unofficial builds for Alpine/musl compatibility
# RUN \
#     ARCH="${BUILD_ARCH:-$(uname -m)}" \
#     && if [ "${ARCH}" = "aarch64" ]; then NODE_ARCH="arm64"; fi \
#     && if [ "${ARCH}" = "amd64" ] || [ "${ARCH}" = "x86_64" ]; then NODE_ARCH="x64"; fi \
#     && if [ "${ARCH}" = "armhf" ] || [ "${ARCH}" = "armv7" ] || [ "${ARCH}" = "armv7l" ]; then NODE_ARCH="armv7l"; fi \
#     && if [ "${ARCH}" = "i386" ] || [ "${ARCH}" = "x86" ]; then NODE_ARCH="x86"; fi \
#     && if [ -z "${NODE_ARCH}" ]; then echo "Error: Unsupported architecture ${ARCH}. BUILD_ARCH=${BUILD_ARCH}" && exit 1; fi \
#     && NODE_VERSION="22.11.0" \
#     && echo "Installing Node.js ${NODE_VERSION} for architecture ${NODE_ARCH} (detected: ${ARCH}, BUILD_ARCH: ${BUILD_ARCH})" \
#     && curl -fsSL "https://unofficial-builds.nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}-musl.tar.xz" -o /tmp/node.tar.xz \
#     && tar -xJf /tmp/node.tar.xz -C /tmp \
#     && mv /tmp/node-v${NODE_VERSION}-linux-${NODE_ARCH}-musl/* /usr/local/ \
#     && rm -rf /tmp/node* \
#     && node --version \
#     && npm --version

# Configure npm for Alpine/musl compatibility
RUN \
    npm config set ignore-scripts false \
    && npm config set audit false \
    && npm config set fund false

# Install ClawdBot globally
# Based on official Docker setup: https://docs.molt.bot/install/docker
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

# Expose ports
EXPOSE 18789 18793

# Run the add-on
CMD ["/run.sh"]
