# Z-Wave Metering Switch MQTT

A SmartThings Edge driver extension intended to bridge existing Z-Wave metering plugs to a local MQTT broker, then to Home Assistant, without using the SmartThings cloud API.

## Target hardware

- SmartThings Hub v2
- Dawon/U+ Z-Wave metering plug fingerprints:
  - Manufacturer ID: `0x018C`
  - Product Type: `0x0042`
- Confirmed user device: `0x018C / 0x0042 / 0x0002` (UPlus SPES-01 10A)

## Shared MQTT Gateway design

The driver now requests creation of one LAN virtual device named **MQTT Gateway** when a Z-Wave plug is initialized. Broker configuration belongs only to this device; Z-Wave plug devices do not expose duplicate broker preferences.

Gateway Preferences:
- MQTT Broker Address (required)
- MQTT Broker Port (default `1883`)
- MQTT Username and MQTT Password (optional)
- MQTT Topic Prefix (default `stzwave`)
- Home Assistant Discovery Prefix (default `homeassistant`)

The Z-Wave plug devices and the LAN Gateway are intended to be managed by the same Edge driver instance. The Gateway preference lookup helper reads `gateway.preferences`; the MQTT transport has not yet been connected to this helper.

## Design goals

1. Preserve switch, power-meter, energy-meter, refresh, and momentary-reset behavior.
2. Keep the SmartThings hub as the Z-Wave controller; no exclusion or re-pairing.
3. Connect directly from Edge to the user's LAN MQTT broker.
4. Publish device state and accept switch commands over MQTT.
5. Support Home Assistant MQTT Discovery.
6. MQTT failures must never prevent normal Z-Wave operation.
7. Keep broker address and credentials out of source code.

## Development status — 0.1.0-dev.6

- Added a dedicated MQTT Gateway LAN device profile with shared broker preferences.
- Removed MQTT broker preferences from the Z-Wave plug profile.
- Added Gateway lookup, preference parsing, and guarded LAN-device creation request from the plug lifecycle.
- MQTT connection supervision, Gateway refresh/reconfigure handling, command routing, packet framing fixes, and Hub v2 runtime validation remain in progress.
- **Not ready to install:** MQTT transport is not yet integrated with the Z-Wave lifecycle/capability handlers.

## Upstream attribution

Based on [lemonade30us/Smartthings-Edge-Driver](https://github.com/lemonade30us/Smartthings-Edge-Driver/tree/main/zwave-metering-switch-v1). Original notices are retained in the derived source files. See [LICENSE](LICENSE).

## MQTT topics

- `<topic-prefix>/<device-id>/state` — retained JSON state
- `<topic-prefix>/<device-id>/set` — `ON` / `OFF`
- `<discovery-prefix>/switch/<device-id>/config`
- `<discovery-prefix>/sensor/<device-id>_power/config`
- `<discovery-prefix>/sensor/<device-id>_energy/config`

## Safety

The upstream driver remains the production driver. Do not switch the live plug to this derivative until it passes compile, packet framing, broker, command, metering, reconnect, and hub-restart tests.
