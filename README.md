# Z-Wave Metering Switch MQTT

A SmartThings Edge driver extension intended to bridge existing Z-Wave metering plugs to a local MQTT broker, then to Home Assistant, without using the SmartThings cloud API.

## Target hardware

- SmartThings Hub v2
- Dawon/U+ Z-Wave metering plug fingerprints:
  - Manufacturer ID: `0x018C`
  - Product Type: `0x0042`
  - Product IDs supported by the upstream driver: `0x0001`–`0x0008`
- Confirmed user device: `0x018C / 0x0042 / 0x0002` (UPlus SPES-01 10A)

## Design goals

1. Preserve the upstream switch, power-meter, energy-meter, refresh, and momentary-reset behavior.
2. Keep the SmartThings hub as the Z-Wave controller. Devices must not be excluded or re-paired as part of this project.
3. Use a direct LAN connection from the Edge driver to a user-managed MQTT broker.
4. Publish device state and accept switch commands over MQTT.
5. Support Home Assistant MQTT Discovery.
6. MQTT failures must never prevent normal Z-Wave operation.

## Network assumptions for the initial deployment

- MQTT broker: Docker VM at `192.168.60.15`
- MQTT port: `1883` for initial LAN-only testing
- Home Assistant consumes the broker through its MQTT integration.

Do not expose unauthenticated MQTT to untrusted networks. Before production use, configure broker credentials and restrict access with firewall rules; TLS can be added where supported by the hub runtime.

## Current status

This repository begins as a derivative of the upstream `zwave-metering-switch-v1` driver. The upstream Z-Wave implementation and Apache-2.0 notices are retained.

The MQTT protocol module is being developed and tested separately before it is attached to device lifecycle handlers. **Do not install this initial development version on the production hub yet.** The first milestone is an off-hub protocol test; the next is a Hub v2 LAN connectivity test with a single plug.

## Upstream attribution

Based on [lemonade30us/Smartthings-Edge-Driver](https://github.com/lemonade30us/Smartthings-Edge-Driver/tree/main/zwave-metering-switch-v1).

The upstream source identifies the driver as `Z-Wave Metering Switch v1`, version `0.1.1`, and includes copyright notices for jido1517 and SmartThings. Those notices are retained in the derived source files. See [LICENSE](LICENSE).

## Planned MQTT topics

Per-device topics will use the SmartThings device UUID as a stable identifier:

- `stzwave/<device-id>/state` — retained JSON state
- `stzwave/<device-id>/set` — commands: `ON` or `OFF`
- `homeassistant/switch/<device-id>/config` — discovery config
- `homeassistant/sensor/<device-id>_power/config` — power sensor discovery
- `homeassistant/sensor/<device-id>_energy/config` — energy sensor discovery

The exact payload schema will be documented after the first end-to-end test.

## Safety

This is experimental software. The upstream driver is the known-good production driver. Keep it installed until this derivative has passed compile, broker, command, metering, reconnect, and hub-restart tests.
