# Changelog

## 0.1.0-dev.2 - 2026-11-24

- Added an isolated MQTT 3.1.1 packet codec for CONNECT, QoS 0 PUBLISH, SUBSCRIBE, PINGREQ, and DISCONNECT packets.
- Added initial Lua smoke tests for packet construction.
- Kept MQTT transport disconnected from the production driver entry point pending protocol and Hub v2 runtime tests.

## 0.1.0-dev.1 - 2026-11-24

- Created a separate derivative project for the SmartThings Z-Wave Metering Switch driver.
- Documented target hardware, architecture, MQTT topic plan, and safety requirements.
- Preserved the upstream driver attribution and Apache-2.0 licensing notices.
- MQTT transport is not yet enabled in the production driver entry point.
