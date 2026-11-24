# Z-Wave Metering Switch MQTT

A SmartThings Edge driver extension intended to bridge existing Z-Wave metering plugs to a local MQTT broker, then to Home Assistant, without using the SmartThings cloud API.

## Target hardware

- SmartThings Hub v2
- Dawon/U+ Z-Wave metering plug fingerprints:
  - Manufacturer ID: `0x018C`
  - Product Type: `0x0042`
- Confirmed user device: `0x018C / 0x0042 / 0x0002` (UPlus SPES-01 10A)

## Design goals

1. Preserve switch, power-meter, energy-meter, refresh, and momentary-reset behavior.
2. Keep the SmartThings hub as the Z-Wave controller; no exclusion or re-pairing.
3. Connect directly from Edge to a user-managed LAN MQTT broker.
4. Publish device state and accept switch commands over MQTT.
5. Support Home Assistant MQTT Discovery.
6. MQTT failures must never prevent normal Z-Wave operation.

## Initial network assumptions

- MQTT broker: Docker VM at `192.168.60.15`
- MQTT port: `1883` for isolated LAN testing
- Home Assistant consumes the broker through its MQTT integration.

Do not expose unauthenticated MQTT to untrusted networks. Use a dedicated broker account and firewall restrictions. TLS support should be validated before deployment.

## Development status — 0.1.0-dev.3

- Imported upstream Z-Wave driver source and Dawon sub-driver with attribution.
- Added MQTT 3.1.1 packet codec and an experimental `cosock.socket` TCP client.
- Added Home Assistant MQTT Discovery payload helpers.
- Added a test plan in [docs/MQTT-TESTING.md](docs/MQTT-TESTING.md).
- **Not ready to install:** MQTT transport is not yet integrated with the Z-Wave lifecycle/capability handlers. TCP stream buffering, inbound command routing, reconnect supervision, credentials/preferences, and Hub v2 runtime tests remain.

## Upstream attribution

Based on [lemonade30us/Smartthings-Edge-Driver](https://github.com/lemonade30us/Smartthings-Edge-Driver/tree/main/zwave-metering-switch-v1). Original notices are retained in the derived source files. See [LICENSE](LICENSE).

## MQTT topics

- `stzwave/<device-id>/state` — retained JSON state
- `stzwave/<device-id>/set` — `ON` / `OFF`
- `homeassistant/switch/<device-id>/config`
- `homeassistant/sensor/<device-id>_power/config`
- `homeassistant/sensor/<device-id>_energy/config`

## Safety

The upstream driver remains the production driver. Do not switch the live plug to this derivative until it passes compile, packet framing, broker, command, metering, reconnect, and hub-restart tests.
