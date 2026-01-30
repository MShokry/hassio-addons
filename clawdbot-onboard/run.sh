#!/usr/bin/env bash
set -e

# Options file path (provided by Home Assistant)
OPTIONS_FILE="/data/options.json"

# Function to get config values from options.json
get_config() {
    local key="$1"
    local default="${2:-}"
    if [ -f "${OPTIONS_FILE}" ]; then
        jq -r ".${key} // \"${default}\"" "${OPTIONS_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

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

get_config_int() {
    local key="$1"
    local default="${2:-0}"
    if [ -f "${OPTIONS_FILE}" ]; then
        jq -r ".${key} // ${default}" "${OPTIONS_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

log_info() { echo "[INFO] $@"; }
log_warn() { echo "[WARN] $@"; }
log_error() { echo "[ERROR] $@"; }

# Basic options for ports and binding
GATEWAY_PORT=$(get_config_int 'gateway_port' '18789')
CANVAS_PORT=$(get_config_int 'canvas_port' '18793')
BIND_ADDRESS=$(get_config 'bind_address' '0.0.0.0')
FORCE_ONBOARD=$(get_config_bool 'force_onboard' 'false')

# Directories for state and persistent config
export CLAWDBOT_STATE_DIR=/data
CONFIG_DIR=/data/clawdbot-config
CONFIG_PATH=${CONFIG_DIR}/clawdbot.json
DEFAULT_CONFIG_PATH=/root/.clawdbot/clawdbot.json

mkdir -p /root/.clawdbot /data /data/workspace ${CONFIG_DIR}

# If a config exists in persistent storage, prefer it
if [ -f "${CONFIG_PATH}" ]; then
  cp -f "${CONFIG_PATH}" "${DEFAULT_CONFIG_PATH}" || true
fi

# Convert bind address to ClawdBot format for gateway
GATEWAY_BIND="${BIND_ADDRESS}"
if [ "${BIND_ADDRESS}" = "0.0.0.0" ]; then
  GATEWAY_BIND="lan"
elif [ "${BIND_ADDRESS}" = "127.0.0.1" ] || [ "${BIND_ADDRESS}" = "localhost" ]; then
  GATEWAY_BIND="loopback"
fi

# Decide mode: onboarding vs gateway
NEED_ONBOARD="false"
if [ "${FORCE_ONBOARD}" = "true" ]; then
  NEED_ONBOARD="true"
elif [ ! -f "${DEFAULT_CONFIG_PATH}" ] && [ ! -f "${CONFIG_PATH}" ]; then
  NEED_ONBOARD="true"
fi

if [ "${NEED_ONBOARD}" = "true" ]; then
  log_info "No config found or force_onboard=true. Starting ClawdBot Onboarding UI..."
  log_info "Canvas (onboarding) port: ${CANVAS_PORT}"
  log_info "After completing onboarding, a config will be saved and persisted."
  
  # Start onboarding experience
  # If the CLI supports --port options for Canvas, it will honor env/args; otherwise defaults
  # We run onboarding in the foreground so HA Ingress can proxy to it.
  exec clawdbot onboard
else
  log_info "Config found. Starting ClawdBot Gateway..."
  log_info "Gateway port: ${GATEWAY_PORT} | Bind: ${GATEWAY_BIND}"
  
  # Persist any config written to default path back to /data
  if [ -f "${DEFAULT_CONFIG_PATH}" ]; then
    mkdir -p "${CONFIG_DIR}"
    cp -f "${DEFAULT_CONFIG_PATH}" "${CONFIG_PATH}" || true
  fi

  GATEWAY_ARGS=(
    --port "${GATEWAY_PORT}"
    --bind "${GATEWAY_BIND}"
  )

  exec clawdbot gateway "${GATEWAY_ARGS[@]}"
fi