# Z-Wave Metering Switch MQTT

A SmartThings Edge driver extension that bridges supported existing Z-Wave metering plugs to a local MQTT broker and Home Assistant, without the SmartThings cloud API.

## Target hardware

- SmartThings Hub v2
- Dawon/U+ Z-Wave metering plug family
- Confirmed user device: UPlus SPES-01 10A, fingerprint `0x018C / 0x0042 / 0x0002`

## Shared MQTT Gateway

The driver requests one LAN virtual device named **MQTT Gateway** when a supported Z-Wave plug initializes. The Gateway owns the broker Preferences. Plug devices do not duplicate these settings.

Configure only the Gateway in SmartThings:
- MQTT Broker Address (required; no address is embedded in source)
- MQTT Broker Port (default `1883`)
- MQTT Username / Password (optional; username is required when a password is set)
- MQTT Topic Prefix (default `stzwave`)
- Home Assistant Discovery Prefix (default `homeassistant`)

All plugs handled by this driver share one MQTT 3.1.1 TCP connection. The connection supervisor reconnects with exponential backoff, subscribes to `<topic-prefix>/+/set`, publishes retained Home Assistant Discovery configuration, and periodically publishes the latest SmartThings capability state. MQTT ON/OFF commands are injected back through the existing SmartThings switch capability handler, preserving the Z-Wave command path.

## MQTT topics

For each plug (device UUID sanitized for topic use):
- `<topic-prefix>/<device-id>/state` — retained JSON with switch, power, energy
- `<topic-prefix>/<device-id>/set` — `ON` or `OFF`
- `<discovery-prefix>/switch/<device-id>/config`
- `<discovery-prefix>/sensor/<device-id>_power/config`
- `<discovery-prefix>/sensor/<device-id>_energy/config`

## Design and safety

- SmartThings Hub v2 remains the Z-Wave controller; no exclusion or re-pairing is intended.
- The original switch, power meter, energy meter, refresh, and momentary reset behavior is retained.
- MQTT errors are isolated in a separate cosock coroutine and do not intentionally block normal Z-Wave handlers.
- The broker should be LAN-only, authenticated, and not exposed to the internet.
- The implementation currently uses MQTT 3.1.1 QoS 0 on TCP/1883. TLS and QoS 1 are not implemented.
- Discovery is retained; state is published every five seconds. HA commands are ON/OFF text payloads.

## Development status — 0.1.0-dev.10

End-to-end code has been connected: Gateway provisioning and Preferences, one shared MQTT worker, reconnect backoff, TCP stream framing, HA Discovery, periodic state publication, and MQTT-to-SmartThings switch command injection. GitHub Actions runs Lua syntax/codec checks and builds the SmartThings Edge package with the official CLI inside an ephemeral Node container. The CLI runs in build-only mode: no SmartThings account authentication, cloud upload, or Hub installation occurs. The generated ZIP is checked and retained as a seven-day CI artifact.

**Still requires validation before installation:** successful CI packaging job completion and profile semantics on Hub v2, Hub v2 Gateway creation, actual Mosquitto CONNECT/SUBSCRIBE/PUBLISH, switch command round-trip, power/energy units, and hub/broker restart behavior. This repository change is not represented as Hub-tested or production-ready.

## Upstream attribution

Derived from [lemonade30us/Smartthings-Edge-Driver](https://github.com/lemonade30us/Smartthings-Edge-Driver/tree/main/zwave-metering-switch-v1). Original attribution and Apache-2.0 licensing are retained; see [LICENSE](LICENSE).
