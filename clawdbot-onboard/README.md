# ClawdBot Onboard Add-on

This add-on launches ClawdBot's onboarding experience inside Home Assistant. It starts with no pre-set configuration and guides you through generating a new `clawdbot.json` that is persisted under `/data/clawdbot-config/`.

## What it does
- Exposes the Canvas (onboarding UI) on port `18793` and via Ingress.
- After onboarding completes, the generated config is saved to `/data/clawdbot-config/clawdbot.json`.
- On next start, if a config exists, the add-on runs the `gateway` on port `18789`.

## Usage
1. Install the add-on (folder `clawdbot-onboard`).
2. Start the add-on and open Ingress from the add-on page.
3. Complete the onboarding flow in the UI.
4. The config will be saved to `/data/clawdbot-config/clawdbot.json`.
5. Restart the add-on to run the gateway with the saved config.

## Options
- `gateway_port` (default `18789`): Port for the gateway when config exists.
- `canvas_port` (default `18793`): Port for onboarding UI.
- `bind_address` (default `0.0.0.0`): Gateway bind address.
- `force_onboard` (default `false`): If `true`, always launch onboarding UI even if a config exists.

## Notes
- The onboarding UI runs until you complete the setup; afterwards, restart the add-on to switch to gateway mode.
- If your environment requires specific API keys or tokens, provide them during onboarding.