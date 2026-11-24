# MQTT integration validation plan

## Current implementation

Version `0.1.0-dev.9` connects the following paths:

- Z-Wave plug initialization requests one LAN virtual device named `MQTT Gateway`.
- MQTT broker preferences are read only from that Gateway device.
- One cosock worker maintains one MQTT 3.1.1 connection for all supported plugs.
- The worker subscribes to `<topic-prefix>/+/set`, publishes Home Assistant MQTT Discovery, and publishes retained state every five seconds.
- Incoming `ON` / `OFF` payloads are routed through `driver:inject_capability_command` to the original SmartThings switch handler.
- Reconnect attempts use exponential backoff; TCP packet fragments are buffered before decoding.

## Before installing on the live Hub v2

1. Run the GitHub Actions Lua syntax and codec tests.
2. Run the SmartThings CLI package validation/build against the current Edge Lua libraries.
3. Confirm the package contains both profiles and the Z-Wave fingerprints.
4. Install on a spare/test Hub if available. If only the live Hub is available, do not switch the live plugs to this driver until the Gateway creation test is complete and a rollback path is prepared.
5. Confirm the Gateway appears once and its Preferences can be saved.

## Broker prerequisites

1. Use the existing Home Assistant Mosquitto broker.
2. Configure a dedicated MQTT username/password.
3. Keep the listener on the trusted LAN only; do not expose TCP/1883 to the internet.
4. Permit the SmartThings Hub v2 to reach the broker on the configured TCP port through the UDM firewall.

## Hub validation sequence

1. Enter broker address, port, username, and password in MQTT Gateway Settings.
2. Verify the Gateway reports no Lua errors and the driver connects to Mosquitto.
3. Confirm the broker receives the Discovery config topics.
4. Confirm each plug appears in Home Assistant without manually creating MQTT entities.
5. Toggle each plug in SmartThings and confirm HA state follows.
6. Toggle each plug in HA and confirm SmartThings and the physical Z-Wave plug follow.
7. Confirm power and energy sensors show plausible values and units.
8. Restart Mosquitto and verify automatic reconnection.
9. Restart the Hub v2 and verify Gateway settings and MQTT reconnection.
10. Change the Gateway broker address or credentials and verify the connection is rebuilt.
11. Confirm SmartThings switch control still works while Mosquitto is stopped.

## Current limitations

- MQTT 3.1.1 QoS 0 only; no QoS 1/2.
- Plain TCP only; TLS is not implemented. Keep the broker on the trusted LAN.
- State is polled from SmartThings' latest capability cache every five seconds.
- Hub v2 runtime and SmartThings CLI validation have not yet been completed.
