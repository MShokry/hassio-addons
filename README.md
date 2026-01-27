# This is a Personal TEST use it on your own risk

# ClawdBot Home Assistant Add-on Repository

This repository contains the ClawdBot add-on for Home Assistant, allowing you to integrate ClawdBot's AI assistant capabilities with your Home Assistant instance.

## What is ClawdBot?

ClawdBot is an AI assistant platform that bridges messaging platforms (WhatsApp, Telegram, Discord, iMessage) to AI agents. With this add-on, you can control and interact with your Home Assistant instance through various chat platforms.

## Installation

1. In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots (⋮) in the top right → **Repositories**
3. Add this repository URL:
   ```
   https://github.com/YOUR_USERNAME/addon-clawdbot
   ```
4. Click **Add** and wait for the repository to load
5. Find **ClawdBot** in the add-on store and click **Install**

## Add-ons in this Repository

### ClawdBot

The main ClawdBot Gateway add-on that provides:
- AI agent integration (Claude, GPT-4, Gemini, etc.)
- Multi-platform messaging support (WhatsApp, Telegram, Discord)
- Home Assistant integration for smart home control
- WebSocket Gateway for real-time communication
- Canvas interface for visual interactions

See the [add-on README](clawdbot/README.md) for detailed documentation.

## Repository Structure

```
.
├── repository.yaml          # Repository metadata
├── clawdbot/                # ClawdBot add-on
│   ├── config.yaml          # Add-on configuration
│   ├── Dockerfile           # Container definition
│   ├── build.yaml           # Build configuration
│   ├── run.sh               # Execution script
│   ├── README.md            # Add-on documentation
│   └── CHANGELOG.md         # Version history
└── README.md                # This file
```

## Support

- **ClawdBot Documentation**: [https://docs.clawd.bot/](https://docs.clawd.bot/)
- **ClawdBot GitHub**: [https://github.com/clawdbot/clawdbot](https://github.com/clawdbot/clawdbot)
- **Issues**: Please report issues on the add-on repository

## License

MIT License - Free as a lobster in the ocean 🦞
