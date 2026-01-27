# ClawdBot Home Assistant Add-on

🦞 AI assistant gateway for Home Assistant integration with WhatsApp, Telegram, Discord, and more.

## About

ClawdBot is an AI assistant platform that bridges messaging platforms (WhatsApp, Telegram, Discord, iMessage) to AI agents. This add-on runs the ClawdBot Gateway, allowing you to control and interact with your Home Assistant instance through various chat platforms.

## Features

- 🤖 **AI Agent Integration** - Connect to Claude, GPT-4, Gemini, and other AI models
- 📱 **Multi-Platform Support** - WhatsApp, Telegram, Discord, and more
- 🏠 **Home Assistant Integration** - Control your smart home through chat
- 🔐 **Secure Configuration** - All settings managed through Home Assistant UI
- 🌐 **WebSocket Gateway** - Real-time communication and control
- 🎨 **Canvas Interface** - Visual workspace for AI interactions

## Installation

1. Add this repository to your Home Assistant add-on store:
   ```
   https://github.com/mshokry/hassio-addons
   ```

2. Go to **Settings** → **Add-ons** → **Add-on Store**

3. Click the three dots (⋮) in the top right → **Repositories**

4. Add the repository URL and click **Add**

5. Find **ClawdBot** in the add-on store and click **Install**

## Configuration

All configuration is done through the Home Assistant add-on configuration UI. No manual file editing required!

### Basic Settings

- **Log Level**: Set logging verbosity (debug, info, warn, error)
- **Gateway Port**: WebSocket port for Gateway (default: 18789)
- **Canvas Port**: HTTP port for Canvas interface (default: 18793)
- **Bind Address**: Network interface to bind to (default: 0.0.0.0 - binds to all interfaces for container use)
- **Gateway Token**: Optional authentication token for Gateway access

### AI Model Configuration

- **Model Provider**: Choose your AI provider (Anthropic, OpenAI, Google, Local)
- **Model Name**: Specific model to use (e.g., "claude-3-5-sonnet-20241022")
- **Anthropic API Key**: Your Anthropic API key (if using Anthropic)
- **OpenAI API Key**: Your OpenAI API key (if using OpenAI)

### Home Assistant Integration

- **Home Assistant URL**: Your Home Assistant instance URL (e.g., "http://homeassistant:8123")
  - *Note: If left empty, the add-on will automatically use the supervisor API (`http://supervisor/core`)*
- **Home Assistant Token**: Long-lived access token from Home Assistant
  - *Note: If left empty and URL is empty, the add-on will try to use the supervisor ingress token*

To create a token manually:
1. Go to your Home Assistant profile
2. Scroll down to **Long-Lived Access Tokens**
3. Click **Create Token**
4. Copy the token and paste it in the add-on configuration

**Automatic Integration**: If you leave both URL and token empty, the add-on will attempt to automatically connect to Home Assistant through the supervisor API. This works for most use cases where the add-on is running on the same Home Assistant instance.

### Channel Configuration

#### WhatsApp
- **Enabled**: Toggle WhatsApp integration
- **Allow From**: List of phone numbers allowed to interact (leave empty for all)

#### Telegram
- **Enabled**: Toggle Telegram integration
- **Bot Token**: Your Telegram bot token from [@BotFather](https://t.me/botfather)

#### Discord
- **Enabled**: Toggle Discord integration
- **Bot Token**: Your Discord bot token from Discord Developer Portal

### Environment Variables

Add custom environment variables as a dictionary (key-value pairs) for advanced configuration.

## Usage

### Starting the Add-on

1. Configure the add-on through the **Configuration** tab
2. Click **Start** to launch the Gateway
3. Check the **Log** tab for startup messages

### Accessing the Gateway

The add-on supports **Ingress** for secure HTTPS access through Home Assistant's web interface:

- **Via Ingress (Recommended)**: Click the **Open Web UI** button in the add-on panel to access the gateway control UI securely through Home Assistant's HTTPS interface
  - URL: `https://your-home-assistant-url/api/hassio_ingress/clawdbot`
  - No need to expose ports or configure HTTP access

- **Direct Port Access** (if needed):
  - **WebSocket**: `ws://localhost:18789` (or your configured bind address)
  - **Canvas UI**: `http://localhost:18793` (or your configured bind address)

### Pairing WhatsApp

1. Ensure WhatsApp channel is enabled in configuration
2. Check the add-on logs for QR code
3. Scan the QR code with your WhatsApp mobile app
4. Wait for "WhatsApp connected" message in logs

### Using with Home Assistant

Once configured with Home Assistant URL and token, ClawdBot can:
- Control devices through chat
- Query sensor states
- Trigger automations
- Get notifications and alerts

Example commands (via WhatsApp/Telegram):
- "Turn on the living room lights"
- "What's the temperature in the bedroom?"
- "Run the goodnight automation"

## Troubleshooting

### Gateway won't start
- Check the logs for error messages
- Verify all required API keys are set
- Ensure ports 18789 and 18793 are not in use by other add-ons

### WhatsApp connection fails
- Make sure WhatsApp channel is enabled
- Check logs for QR code
- Ensure your phone has internet connection when scanning

### Home Assistant integration not working
- Verify Home Assistant URL is correct (use internal URL if on same network)
- Check that the access token is valid and has proper permissions
- Ensure Home Assistant is accessible from the add-on container

### Model API errors
- Verify your API keys are correct
- Check your API provider account for rate limits or quotas
- Review logs for specific error messages

## Support

- **Documentation**: [https://docs.clawd.bot/](https://docs.clawd.bot/)
- **GitHub**: [https://github.com/clawdbot/clawdbot](https://github.com/clawdbot/clawdbot)
- **Issues**: Report issues on the add-on repository

## License

MIT License - Free as a lobster in the ocean 🦞
