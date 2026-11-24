# Changelog

## 0.1.0-dev.5 - 2026-11-24

- Added a dedicated MQTT Gateway LAN device profile to hold shared broker preferences.
- Moved broker address, port, credentials, topic prefix, and Home Assistant discovery prefix out of the Z-Wave plug profile and into the Gateway profile.
- Documented the shared single-connection architecture and current implementation status.
- Gateway creation and runtime MQTT integration remain in progress; not ready for installation.

## 0.1.0-dev.4 - 2026-11-24

- Added SmartThings device Preferences for MQTT broker address, port, optional username/password, state topic prefix, and Home Assistant Discovery prefix.
- Documented that SmartThings Preferences are device-scoped and must currently be set per plug.
- Documented that broker addresses and credentials are not stored in source code.
- MQTT transport remains experimental and is not wired into Z-Wave lifecycle/capability handlers.

## 0.1.0-dev.3 - 2026-11-24

- Added an experimental MQTT 3.1.1 TCP client using SmartThings Edge `cosock.socket`.
- Added MQTT Home Assistant Discovery payload helpers.
- Added an MQTT integration test plan and documented current transport limitations.
- MQTT client is not wired into Z-Wave lifecycle/capability handlers; not ready for Hub v2 installation.

## 0.1.0-dev.2 - 2026-11-24

- Added an isolated MQTT 3.1.1 packet codec for CONNECT, QoS 0 PUBLISH, SUBSCRIBE, PINGREQ, and DISCONNECT packets.
- Added initial Lua smoke tests for packet construction.
- Kept MQTT transport disconnected from the production driver entry point pending protocol and Hub v2 runtime tests.

## 0.1.0-dev.1 - 2026-11-24

- Created a separate derivative project for the SmartThings Z-Wave Metering Switch driver.
- Documented target hardware, architecture, MQTT topic plan, and safety requirements.
- Preserved the upstream driver attribution and Apache-2.0 licensing notices.
- MQTT transport is not yet enabled in the production driver entry point.
