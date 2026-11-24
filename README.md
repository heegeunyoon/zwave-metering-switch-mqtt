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
7. Keep broker address and credentials out of source code; configure them in SmartThings device Preferences.

## MQTT connection settings

The device profile exposes these Preferences:

- MQTT Broker Address — required; enter the Home Assistant Mosquitto broker hostname or IP.
- MQTT Broker Port — defaults to `1883`.
- MQTT Username / MQTT Password — optional; password uses a password-type preference.
- MQTT Topic Prefix — defaults to `stzwave`.
- Home Assistant Discovery Prefix — defaults to `homeassistant`.

SmartThings Edge Preferences are device-scoped. With the current profile, the same broker settings must be entered for each plug. The driver code will read these values from `device.preferences`; no broker address, username, or password is embedded in Lua source or committed to Git.

## Development status — 0.1.0-dev.4

- Imported upstream Z-Wave driver source and Dawon sub-driver with attribution.
- Added MQTT 3.1.1 packet codec and an experimental `cosock.socket` TCP client.
- Added Home Assistant MQTT Discovery payload helpers.
- Added configurable MQTT broker, port, credentials, and topic prefixes to the SmartThings device profile.
- Added a test plan in [docs/MQTT-TESTING.md](docs/MQTT-TESTING.md).
- **Not ready to install:** MQTT transport is not yet integrated with the Z-Wave lifecycle/capability handlers. TCP stream buffering, inbound command routing, reconnect supervision, preference-change handling, and Hub v2 runtime tests remain.

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
