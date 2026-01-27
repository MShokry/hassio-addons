#!/usr/bin/with-contenv bashio
set -e

# Get configuration from Home Assistant
LOG_LEVEL=$(bashio::config 'log_level')
GATEWAY_PORT=$(bashio::config 'gateway_port')
CANVAS_PORT=$(bashio::config 'canvas_port')
GATEWAY_TOKEN=$(bashio::config 'gateway_token')
BIND_ADDRESS=$(bashio::config 'bind_address')
HOMEASSISTANT_URL=$(bashio::config 'homeassistant_url')
HOMEASSISTANT_TOKEN=$(bashio::config 'homeassistant_token')
OPENAI_API_KEY=$(bashio::config 'openai_api_key')
ANTHROPIC_API_KEY=$(bashio::config 'anthropic_api_key')
MODEL_PROVIDER=$(bashio::config 'model_provider')
MODEL_NAME=$(bashio::config 'model_name')

# Set ClawdBot directories (based on official Docker setup)
# State directory for agents, sessions, and workspace
export CLAWDBOT_STATE_DIR=/data
# Config file path
export CLAWDBOT_CONFIG_PATH=/data/clawdbot.json
# Workspace directory (optional, defaults to ~/clawd)
export CLAWDBOT_WORKSPACE_DIR=/data/workspace

# Create necessary directories
mkdir -p /data /data/workspace /data/agents /data/sessions

# Get channel configurations
WHATSAPP_ENABLED=$(bashio::config 'channels.whatsapp.enabled')
TELEGRAM_ENABLED=$(bashio::config 'channels.telegram.enabled')
TELEGRAM_TOKEN=$(bashio::config 'channels.telegram.bot_token')
DISCORD_ENABLED=$(bashio::config 'channels.discord.enabled')
DISCORD_TOKEN=$(bashio::config 'channels.discord.bot_token')

# Get allow_from list for WhatsApp using jq
if bashio::fs.file_exists "/data/options.json"; then
  WHATSAPP_ALLOW_FROM=$(jq -r '.channels.whatsapp.allow_from // []' /data/options.json)
else
  WHATSAPP_ALLOW_FROM="[]"
fi

# Build ClawdBot configuration JSON
CONFIG_JSON=$(jq -n \
  --argjson gateway_port "${GATEWAY_PORT}" \
  --argjson canvas_port "${CANVAS_PORT}" \
  --arg bind_address "${BIND_ADDRESS}" \
  --arg gateway_token "${GATEWAY_TOKEN}" \
  --arg model_provider "${MODEL_PROVIDER}" \
  --arg model_name "${MODEL_NAME}" \
  --argjson whatsapp_enabled "${WHATSAPP_ENABLED}" \
  --argjson whatsapp_allow_from "${WHATSAPP_ALLOW_FROM}" \
  --argjson telegram_enabled "${TELEGRAM_ENABLED}" \
  --arg telegram_token "${TELEGRAM_TOKEN}" \
  --argjson discord_enabled "${DISCORD_ENABLED}" \
  --arg discord_token "${DISCORD_TOKEN}" \
  '{
    gateway: {
      port: $gateway_port,
      canvasHost: {
        port: $canvas_port
      },
      bind: $bind_address,
      token: (if $gateway_token == "" then null else $gateway_token end)
    },
    models: {
      provider: $model_provider,
      name: $model_name
    },
    channels: {
      whatsapp: {
        enabled: $whatsapp_enabled,
        allowFrom: $whatsapp_allow_from
      },
      telegram: {
        enabled: $telegram_enabled,
        botToken: (if $telegram_token == "" then null else $telegram_token end)
      },
      discord: {
        enabled: $discord_enabled,
        botToken: (if $discord_token == "" then null else $discord_token end)
      }
    }
  }')

# Write configuration file
echo "${CONFIG_JSON}" > /data/clawdbot.json

# Set API keys as environment variables if provided
if [ -n "${OPENAI_API_KEY}" ] && [ "${OPENAI_API_KEY}" != "" ]; then
  export OPENAI_API_KEY
fi

if [ -n "${ANTHROPIC_API_KEY}" ] && [ "${ANTHROPIC_API_KEY}" != "" ]; then
  export ANTHROPIC_API_KEY
fi

# Set Home Assistant integration
# If URL not provided, use supervisor API
if [ -z "${HOMEASSISTANT_URL}" ] || [ "${HOMEASSISTANT_URL}" == "" ]; then
  HOMEASSISTANT_URL="http://supervisor/core"
  bashio::log.info "Using default Home Assistant URL: ${HOMEASSISTANT_URL}"
fi

# If token not provided, try to get it from supervisor
if [ -z "${HOMEASSISTANT_TOKEN}" ] || [ "${HOMEASSISTANT_TOKEN}" == "" ]; then
  if bashio::var.has_value "$(bashio::addon.ingress_token)"; then
    HOMEASSISTANT_TOKEN=$(bashio::addon.ingress_token)
    bashio::log.info "Using supervisor ingress token for Home Assistant"
  fi
fi

# Export Home Assistant variables if available
if [ -n "${HOMEASSISTANT_URL}" ] && [ "${HOMEASSISTANT_URL}" != "" ]; then
  export HOMEASSISTANT_URL
  if [ -n "${HOMEASSISTANT_TOKEN}" ] && [ "${HOMEASSISTANT_TOKEN}" != "" ]; then
    export HOMEASSISTANT_TOKEN
    bashio::log.info "Home Assistant integration enabled: ${HOMEASSISTANT_URL}"
  else
    bashio::log.warning "Home Assistant URL set but no token provided"
  fi
fi

# Set log level
export LOG_LEVEL=${LOG_LEVEL}

# Add any additional environment variables
ENV_VARS=$(bashio::config 'environment')
if [ -n "${ENV_VARS}" ] && [ "${ENV_VARS}" != "null" ]; then
  for key in $(echo "${ENV_VARS}" | jq -r 'keys[]'); do
    value=$(echo "${ENV_VARS}" | jq -r ".[\"$key\"]")
    export "${key}=${value}"
  done
fi

# Log startup
bashio::log.info "Starting ClawdBot Gateway..."
bashio::log.info "Gateway port: ${GATEWAY_PORT}"
bashio::log.info "Canvas port: ${CANVAS_PORT}"
bashio::log.info "Model provider: ${MODEL_PROVIDER}"
bashio::log.info "Model name: ${MODEL_NAME}"

# Build command arguments
# Based on official Docker setup: gateway bind defaults to "lan" for container use
# For Home Assistant, we use the configured bind address
GATEWAY_ARGS=(
  --port "${GATEWAY_PORT}"
  --bind "${BIND_ADDRESS}"
)

# Add token if provided (required for non-loopback binds per docs)
if [ -n "${GATEWAY_TOKEN}" ] && [ "${GATEWAY_TOKEN}" != "" ]; then
  GATEWAY_ARGS+=(--token "${GATEWAY_TOKEN}")
elif [ "${BIND_ADDRESS}" != "127.0.0.1" ] && [ "${BIND_ADDRESS}" != "localhost" ]; then
  # Token is required for non-loopback binds per documentation
  bashio::log.warning "Gateway token recommended for non-loopback bind address"
fi

# Start ClawdBot Gateway
# Reference: https://docs.molt.bot/install/docker
exec clawdbot gateway "${GATEWAY_ARGS[@]}"
