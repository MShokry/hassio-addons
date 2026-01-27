# Changelog

All notable changes to this add-on will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.12] - 2026-01-27

### Changed
- Configuration file now saved to `/root/.clawdbot/clawdbot.json` (matching ClawdBot conventions)
- Updated `CLAWDBOT_CONFIG_PATH` environment variable to point to `/root/.clawdbot/clawdbot.json`
- Improved script structure: moved logging functions earlier for better organization
- Added logging when configuration file is saved

## [1.0.11] - 2026-01-27

### Improved
- Added documentation and comments explaining the relationship between `ingress_port`, `gateway_port`, and exposed ports
- Clarified that `ingress_port` in config.yaml is static and should match the `gateway_port` option
- Updated port descriptions to indicate they match the corresponding options
- Enhanced README with port configuration notes and warnings about changing ports

## [1.0.10] - 2026-01-27

### Improved
- Enhanced logging for ingress connectivity
- Added warning when binding to loopback address (may prevent ingress)
- Added troubleshooting section for 503 Service Unavailable errors

## [1.0.9] - 2026-01-27

### Added
- **Ingress support**: Added ingress configuration to enable secure HTTPS access through Home Assistant's web interface
  - "Open Web UI" button now available in the add-on panel
  - Access the gateway control UI securely via HTTPS without exposing ports
  - Fully integrated with Home Assistant's authentication system

## [1.0.8] - 2026-01-27

### Fixed
- Fixed bind address format conversion (0.0.0.0 → "lan", 127.0.0.1 → "loopback")
- Fixed ClawdBot configuration structure to match current schema:
  - Moved models to `agents.defaults.model.primary` format
  - Moved canvasHost to top-level (not under gateway)
  - Removed deprecated `enabled` fields from channels
  - Changed Discord `botToken` to `token`
  - Fixed gateway.auth.token structure
- Fixed S6 overlay compatibility (init: false)
- Fixed configuration reading to work without bashio API access
- Improved error handling and logging

### Changed
- Updated to use Alpine's nodejs package instead of manual Node.js installation
- Improved architecture detection with fallback to uname
- Enhanced configuration validation and type handling

## [1.0.0] - 2026-01-27

### Added
- Initial release of ClawdBot Home Assistant add-on
- Gateway WebSocket server on port 18789
- Canvas HTTP server on port 18793
- Support for multiple AI model providers (Anthropic, OpenAI, Google, Local)
- WhatsApp integration via Baileys
- Telegram bot integration
- Discord bot integration
- Home Assistant integration for smart home control
- Comprehensive configuration schema in Home Assistant UI
- Support for all Home Assistant architectures (aarch64, amd64, armhf, armv7)
- Environment variable configuration
- Logging configuration with multiple levels

### Features
- Full Home Assistant configuration UI integration
- Secure API key management
- Multi-channel messaging support
- Real-time WebSocket communication
- Visual Canvas interface
