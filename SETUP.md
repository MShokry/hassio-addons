# ClawdBot Home Assistant Add-on - Setup Guide

## Repository Structure

```
addon-clawdbot/
├── repository.yaml          # Repository metadata for Home Assistant
├── README.md                # Main repository documentation
├── LICENSE                  # MIT License
├── .gitignore              # Git ignore rules
└── clawdbot/               # ClawdBot add-on
    ├── config.yaml         # Add-on configuration and schema
    ├── Dockerfile          # Container build definition
    ├── build.yaml          # Build configuration for different architectures
    ├── run.sh              # Startup script (handles configuration)
    ├── README.md           # Add-on specific documentation
    └── CHANGELOG.md        # Version history
```

## Key Features

### ✅ Complete Home Assistant Integration
- All configuration exposed through Home Assistant UI
- Automatic Home Assistant URL detection (uses supervisor API if not specified)
- Secure token management
- Full schema validation

### ✅ Comprehensive Configuration Options
- **Gateway Settings**: Port, bind address, authentication token
- **AI Model Configuration**: Provider selection (Anthropic, OpenAI, Google, Local), model name, API keys
- **Channel Support**: WhatsApp, Telegram, Discord with individual settings
- **Home Assistant Integration**: URL and token configuration
- **Environment Variables**: Custom environment variables support
- **Logging**: Configurable log levels

### ✅ Multi-Architecture Support
- aarch64 (ARM 64-bit)
- amd64 (x86_64)
- armhf (ARM 32-bit hard float)
- armv7 (ARMv7)

## Installation Steps

1. **Push to GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: ClawdBot Home Assistant add-on"
   git remote add origin https://github.com/mshokry/hassio-addons.git
   git push -u origin main
   ```

2. **Add Repository to Home Assistant**
   - Go to **Settings** → **Add-ons** → **Add-on Store**
   - Click the three dots (⋮) → **Repositories**
   - Add: `https://github.com/mshokry/hassio-addons`
   - Click **Add**

3. **Install the Add-on**
   - Find **ClawdBot** in the add-on store
   - Click **Install**
   - Wait for installation to complete

4. **Configure the Add-on**
   - Go to the **Configuration** tab
   - Set your API keys (Anthropic, OpenAI, etc.)
   - Configure channels (WhatsApp, Telegram, Discord)
   - Set Home Assistant integration (optional - auto-detects if empty)
   - Click **Save**

5. **Start the Add-on**
   - Click **Start**
   - Check the **Log** tab for startup messages

## Configuration Schema

All settings are available in the Home Assistant UI with proper validation:

- **Select dropdowns** for log level, model provider
- **Integer inputs** for ports
- **String inputs** for URLs, tokens, model names
- **Boolean toggles** for channel enablement
- **List inputs** for WhatsApp allow_from numbers
- **Dictionary inputs** for environment variables

## How It Works

1. **Configuration**: User sets options in Home Assistant UI
2. **Startup**: `run.sh` reads configuration via `bashio`
3. **JSON Generation**: Script creates `clawdbot.json` from Home Assistant config
4. **Environment**: API keys and tokens exported as environment variables
5. **Gateway**: ClawdBot Gateway starts with the configuration

## Testing

Before publishing, test the add-on:

1. Build locally (if possible) or test in Home Assistant
2. Verify all configuration options appear in UI
3. Test with minimal configuration (just API keys)
4. Test Home Assistant auto-detection
5. Test each channel individually
6. Verify logs show correct configuration

## Next Steps

- [ ] Test the add-on in a Home Assistant instance
- [ ] Add icon.png and logo.png for better UI
- [ ] Update version numbers as you make changes
- [ ] Add more channel configurations if needed
- [ ] Document any additional ClawdBot features

## Support

- ClawdBot Docs: https://docs.clawd.bot/
- Home Assistant Add-on Docs: https://developers.home-assistant.io/docs/add-ons/
