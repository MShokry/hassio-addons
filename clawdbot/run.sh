#!/usr/bin/env bash
set -e

# Options file path
OPTIONS_FILE="/data/options.json"

# Function to get config value (reads directly from options.json)
get_config() {
    local key="$1"
    local default="${2:-}"
    if [ -f "${OPTIONS_FILE}" ]; then
        jq -r ".${key} // \"${default}\"" "${OPTIONS_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

# Function to get boolean config value
get_config_bool() {
    local key="$1"
    local default="${2:-false}"
    if [ -f "${OPTIONS_FILE}" ]; then
        local value=$(jq -r ".${key} // ${default}" "${OPTIONS_FILE}" 2>/dev/null)
        if [ "$value" = "true" ] || [ "$value" = "1" ]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "${default}"
    fi
}

# Function to get integer config value
get_config_int() {
    local key="$1"
    local default="${2:-0}"
    if [ -f "${OPTIONS_FILE}" ]; then
        jq -r ".${key} // ${default}" "${OPTIONS_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

# Get configuration from Home Assistant options.json
LOG_LEVEL=$(get_config 'log_level' 'info')
GATEWAY_PORT=$(get_config_int 'gateway_port' '18789')
CANVAS_PORT=$(get_config_int 'canvas_port' '18793')
GATEWAY_TOKEN=$(get_config 'gateway_token' '')
BIND_ADDRESS=$(get_config 'bind_address' '0.0.0.0')
HOMEASSISTANT_URL=$(get_config 'homeassistant_url' '')
HOMEASSISTANT_TOKEN=$(get_config 'homeassistant_token' '')
OPENAI_API_KEY=$(get_config 'openai_api_key' '')
ANTHROPIC_API_KEY=$(get_config 'anthropic_api_key' '')
MODEL_PROVIDER=$(get_config 'model_provider' 'anthropic')
MODEL_NAME=$(get_config 'model_name' 'claude-3-5-sonnet-20241022')

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
WHATSAPP_ENABLED=$(get_config_bool 'channels.whatsapp.enabled' 'false')
TELEGRAM_ENABLED=$(get_config_bool 'channels.telegram.enabled' 'false')
TELEGRAM_TOKEN=$(get_config 'channels.telegram.bot_token' '')
DISCORD_ENABLED=$(get_config_bool 'channels.discord.enabled' 'false')
DISCORD_TOKEN=$(get_config 'channels.discord.bot_token' '')

# Get allow_from list for WhatsApp using jq
if [ -f "${OPTIONS_FILE}" ]; then
  WHATSAPP_ALLOW_FROM=$(jq -c '.channels.whatsapp.allow_from // []' "${OPTIONS_FILE}" 2>/dev/null || echo "[]")
else
  WHATSAPP_ALLOW_FROM="[]"
fi

# Build ClawdBot configuration JSON
# Convert boolean strings to actual booleans for jq
WHATSAPP_ENABLED_JSON="false"
[ "${WHATSAPP_ENABLED}" = "true" ] && WHATSAPP_ENABLED_JSON="true"
TELEGRAM_ENABLED_JSON="false"
[ "${TELEGRAM_ENABLED}" = "true" ] && TELEGRAM_ENABLED_JSON="true"
DISCORD_ENABLED_JSON="false"
[ "${DISCORD_ENABLED}" = "true" ] && DISCORD_ENABLED_JSON="true"

# Build ClawdBot configuration JSON (using current format per docs.clawd.bot)
# Based on: https://docs.clawd.bot/gateway/configuration
CONFIG_JSON=$(jq -n \
  --argjson gateway_port "${GATEWAY_PORT}" \
  --argjson canvas_port "${CANVAS_PORT}" \
  --arg bind_address "${BIND_ADDRESS}" \
  --arg gateway_token "${GATEWAY_TOKEN}" \
  --arg model_provider "${MODEL_PROVIDER}" \
  --arg model_name "${MODEL_NAME}" \
  --argjson whatsapp_allow_from "${WHATSAPP_ALLOW_FROM}" \
  --arg telegram_token "${TELEGRAM_TOKEN}" \
  --arg discord_token "${DISCORD_TOKEN}" \
  --argjson whatsapp_enabled "${WHATSAPP_ENABLED_JSON}" \
  --argjson telegram_enabled "${TELEGRAM_ENABLED_JSON}" \
  --argjson discord_enabled "${DISCORD_ENABLED_JSON}" \
  '{
    gateway: {
      mode: "local",
      port: $gateway_port,
      bind: (if $bind_address == "0.0.0.0" then "lan" else $bind_address end),
      auth: {
        token: (if $gateway_token == "" then null else $gateway_token end)
      }
    },
    canvasHost: {
      port: $canvas_port
    },
    agents: {
      defaults: {
        model: {
          primary: (if $model_provider != "" and $model_name != "" then ($model_provider + "/" + $model_name) else "anthropic/claude-3-5-sonnet-20241022" end)
        }
      }
    },
    channels: (
      {} |
      (if $whatsapp_enabled == true then . + {whatsapp: {allowFrom: $whatsapp_allow_from}} else . end) |
      (if $telegram_enabled == true and $telegram_token != "" then . + {telegram: {botToken: $telegram_token}} else . end) |
      (if $discord_enabled == true and $discord_token != "" then . + {discord: {token: $discord_token}} else . end)
    )
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

# Logging functions
log_info() {
    echo "[INFO] $@"
}

log_warning() {
    echo "[WARN] $@"
}

log_error() {
    echo "[ERROR] $@"
}

# Set Home Assistant integration
# If URL not provided, use supervisor API
if [ -z "${HOMEASSISTANT_URL}" ] || [ "${HOMEASSISTANT_URL}" == "" ]; then
  HOMEASSISTANT_URL="http://supervisor/core"
  log_info "Using default Home Assistant URL: ${HOMEASSISTANT_URL}"
fi

# If token not provided, try to get it from supervisor ingress token
# Note: With init: false, we can't access supervisor API directly
# Users should set the token in the addon configuration
if [ -z "${HOMEASSISTANT_TOKEN}" ] || [ "${HOMEASSISTANT_TOKEN}" == "" ]; then
  log_info "Home Assistant token not provided - integration may be limited"
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
if [ -f "${OPTIONS_FILE}" ]; then
  ENV_VARS=$(jq -c '.environment // {}' "${OPTIONS_FILE}" 2>/dev/null || echo "{}")
  if [ -n "${ENV_VARS}" ] && [ "${ENV_VARS}" != "null" ] && [ "${ENV_VARS}" != "{}" ]; then
    for key in $(echo "${ENV_VARS}" | jq -r 'keys[]' 2>/dev/null); do
      value=$(echo "${ENV_VARS}" | jq -r ".[\"$key\"]" 2>/dev/null)
      if [ -n "${value}" ] && [ "${value}" != "null" ]; then
        export "${key}=${value}"
      fi
    done
  fi
fi

# Convert bind address to ClawdBot format
# Valid values: "loopback", "lan", "tailnet", "auto", "custom", or IP address
GATEWAY_BIND="${BIND_ADDRESS}"
if [ "${BIND_ADDRESS}" = "0.0.0.0" ]; then
  GATEWAY_BIND="lan"
elif [ "${BIND_ADDRESS}" = "127.0.0.1" ] || [ "${BIND_ADDRESS}" = "localhost" ]; then
  GATEWAY_BIND="loopback"
fi

# Log startup
log_info "Starting ClawdBot Gateway..."
log_info "Gateway port: ${GATEWAY_PORT}"
log_info "Canvas port: ${CANVAS_PORT}"
log_info "Gateway bind: ${GATEWAY_BIND} (from ${BIND_ADDRESS})"
log_info "Model provider: ${MODEL_PROVIDER}"
log_info "Model name: ${MODEL_NAME}"

# Build command arguments
# Based on official Docker setup: gateway bind defaults to "lan" for container use
# For Home Assistant, we convert IP addresses to ClawdBot format
GATEWAY_ARGS=(
  --port "${GATEWAY_PORT}"
  --bind "${GATEWAY_BIND}"
)

# Add token if provided (required for non-loopback binds per docs)
if [ -n "${GATEWAY_TOKEN}" ] && [ "${GATEWAY_TOKEN}" != "" ]; then
  GATEWAY_ARGS+=(--token "${GATEWAY_TOKEN}")
elif [ "${GATEWAY_BIND}" != "loopback" ]; then
  # Token is required for non-loopback binds per documentation
  log_warning "Gateway token recommended for non-loopback bind address (${GATEWAY_BIND})"
fi

# Start ClawdBot Gateway
# Reference: https://docs.molt.bot/install/docker
exec clawdbot gateway "${GATEWAY_ARGS[@]}"
