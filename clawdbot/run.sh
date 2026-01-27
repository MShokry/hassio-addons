#!/usr/bin/env bash
set -e

# Load bashio if available (for init: false mode)
if [ -f /usr/lib/bashio/bashio.sh ]; then
    . /usr/lib/bashio/bashio.sh
    USE_BASHIO=true
else
    USE_BASHIO=false
fi

# Function to get config value
get_config() {
    local key="$1"
    if [ "$USE_BASHIO" = "true" ] && command -v bashio::config >/dev/null 2>&1; then
        bashio::config "$key"
    else
        jq -r ".${key} // empty" /data/options.json 2>/dev/null || echo ""
    fi
}

# Get configuration from Home Assistant
LOG_LEVEL=$(get_config 'log_level')
GATEWAY_PORT=$(get_config 'gateway_port')
CANVAS_PORT=$(get_config 'canvas_port')
GATEWAY_TOKEN=$(get_config 'gateway_token')
BIND_ADDRESS=$(get_config 'bind_address')
HOMEASSISTANT_URL=$(get_config 'homeassistant_url')
HOMEASSISTANT_TOKEN=$(get_config 'homeassistant_token')
OPENAI_API_KEY=$(get_config 'openai_api_key')
ANTHROPIC_API_KEY=$(get_config 'anthropic_api_key')
MODEL_PROVIDER=$(get_config 'model_provider')
MODEL_NAME=$(get_config 'model_name')

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
WHATSAPP_ENABLED=$(get_config 'channels.whatsapp.enabled')
TELEGRAM_ENABLED=$(get_config 'channels.telegram.enabled')
TELEGRAM_TOKEN=$(get_config 'channels.telegram.bot_token')
DISCORD_ENABLED=$(get_config 'channels.discord.enabled')
DISCORD_TOKEN=$(get_config 'channels.discord.bot_token')

# Get allow_from list for WhatsApp using jq
if [ -f "/data/options.json" ]; then
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

# Logging function
log_info() {
    if [ "$USE_BASHIO" = "true" ] && command -v bashio::log.info >/dev/null 2>&1; then
        bashio::log.info "$@"
    else
        echo "[INFO] $@"
    fi
}

log_warning() {
    if [ "$USE_BASHIO" = "true" ] && command -v bashio::log.warning >/dev/null 2>&1; then
        bashio::log.warning "$@"
    else
        echo "[WARN] $@"
    fi
}

# Set Home Assistant integration
# If URL not provided, use supervisor API
if [ -z "${HOMEASSISTANT_URL}" ] || [ "${HOMEASSISTANT_URL}" == "" ]; then
  HOMEASSISTANT_URL="http://supervisor/core"
  log_info "Using default Home Assistant URL: ${HOMEASSISTANT_URL}"
fi

# If token not provided, try to get it from supervisor (only if bashio available)
if [ -z "${HOMEASSISTANT_TOKEN}" ] || [ "${HOMEASSISTANT_TOKEN}" == "" ]; then
  if [ "$USE_BASHIO" = "true" ] && command -v bashio::addon.ingress_token >/dev/null 2>&1; then
    if bashio::var.has_value "$(bashio::addon.ingress_token)"; then
      HOMEASSISTANT_TOKEN=$(bashio::addon.ingress_token)
      log_info "Using supervisor ingress token for Home Assistant"
    fi
  fi
fi

# Export Home Assistant variables if available
if [ -n "${HOMEASSISTANT_URL}" ] && [ "${HOMEASSISTANT_URL}" != "" ]; then
  export HOMEASSISTANT_URL
  if [ -n "${HOMEASSISTANT_TOKEN}" ] && [ "${HOMEASSISTANT_TOKEN}" != "" ]; then
    export HOMEASSISTANT_TOKEN
    log_info "Home Assistant integration enabled: ${HOMEASSISTANT_URL}"
  else
    log_warning "Home Assistant URL set but no token provided"
  fi
fi

# Set log level
export LOG_LEVEL=${LOG_LEVEL}

# Add any additional environment variables
ENV_VARS=$(get_config 'environment')
if [ -n "${ENV_VARS}" ] && [ "${ENV_VARS}" != "null" ] && [ "${ENV_VARS}" != "{}" ]; then
  for key in $(echo "${ENV_VARS}" | jq -r 'keys[]' 2>/dev/null); do
    value=$(echo "${ENV_VARS}" | jq -r ".[\"$key\"]" 2>/dev/null)
    export "${key}=${value}"
  done
fi

# Log startup
log_info "Starting ClawdBot Gateway..."
log_info "Gateway port: ${GATEWAY_PORT}"
log_info "Canvas port: ${CANVAS_PORT}"
log_info "Model provider: ${MODEL_PROVIDER}"
log_info "Model name: ${MODEL_NAME}"

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
  log_warning "Gateway token recommended for non-loopback bind address"
fi

# Start ClawdBot Gateway
# Reference: https://docs.molt.bot/install/docker
exec clawdbot gateway "${GATEWAY_ARGS[@]}"
