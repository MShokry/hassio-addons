ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Node.js 22
RUN \
    ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "aarch64" ]; then ARCH="arm64"; fi \
    && if [ "${BUILD_ARCH}" = "armhf" ] || [ "${BUILD_ARCH}" = "armv7" ]; then ARCH="armv7l"; fi \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends \
        nodejs \
        curl \
        ca-certificates \
        jq \
        && npm install -g clawdbot@latest \
    && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /data /config

# Copy run script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /data

# Expose ports
EXPOSE 18789 18793

# Run the add-on
CMD ["/run.sh"]
