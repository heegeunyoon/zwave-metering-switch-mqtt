# Changelog

## 0.1.0-dev.9 - 2026-11-24

- Replaced the outdated MQTT scaffold test plan with the complete end-to-end Hub v2 validation checklist.
- Documented current QoS 0 / plain TCP limitations and required LAN security controls.
- Updated README and VERSION.

## 0.1.0-dev.8 - 2026-11-24

- Validated MQTT Gateway preference values, including integer port bounds and password/username pairing.
- Added a supervisor-level recovery guard for unexpected MQTT worker runtime errors.
- Added GitHub Actions checks for Lua syntax and MQTT codec/stream-framing tests.
- Hub v2 runtime and SmartThings CLI package validation remain required; not a production release.

## 0.1.0-dev.7 - 2026-11-24

- Connected the MQTT Gateway lifecycle and shared MQTT service.
- Added a single MQTT 3.1.1 connection supervisor with reconnect backoff and keepalive.
- Added buffered TCP stream framing so fragmented MQTT packets are accumulated before decoding.
- Added retained Home Assistant MQTT Discovery configuration and periodic retained switch/power/energy state publication.
- Added MQTT ON/OFF command subscription and routing through SmartThings' capability command dispatcher.
- Added Gateway preference-change/reconfigure handling and preserved normal Z-Wave refresh behavior for plugs.
- Added stream-framing tests and updated the development status.
- Hub v2 runtime and package validation remain required; this is not a production release.

## 0.1.0-dev.6 - 2026-11-24

- Added shared MQTT Gateway lookup and preference parsing.
- Added guarded automatic creation request for one LAN Gateway device during Z-Wave plug initialization.
- Excluded the LAN Gateway from the plug's Z-Wave refresh-on-added behavior.
- MQTT transport is still not wired to the driver lifecycle or capability events; not ready for installation.

## 0.1.0-dev.5 - 2026-11-24

- Added a dedicated MQTT Gateway LAN device profile to hold shared broker preferences.
- Moved broker address, port, credentials, topic prefix, and Home Assistant discovery prefix out of the Z-Wave plug profile and into the Gateway profile.
- Documented the shared single-connection architecture and current implementation status.
- Gateway creation and runtime MQTT integration remain in progress; not ready for installation.

## 0.1.0-dev.4 - 2026-11-24

- Added SmartThings device Preferences for MQTT broker address, port, optional username/password, state topic prefix, and Home Assistant Discovery prefix.
- Documented that SmartThings Preferences are device-scoped and must currently be set per plug.
- Documented that broker addresses and credentials are not stored in source code.
- MQTT transport remains experimental and is not wired to Z-Wave lifecycle/capability handlers.

## 0.1.0-dev.3 - 2026-11-24

- Added an experimental MQTT 3.1.1 TCP client using SmartThings Edge `cosock.socket`.
- Added MQTT Home Assistant Discovery payload helpers.
- Added an MQTT integration test plan and documented current transport limitations.
- MQTT client is not wired to Z-Wave lifecycle/capability handlers; not ready for Hub v2 installation.

## 0.1.0-dev.2 - 2026-11-24

- Added an isolated MQTT 3.1.1 packet codec for CONNECT, QoS 0 PUBLISH, SUBSCRIBE, PINGREQ, and DISCONNECT packets.
- Added initial Lua smoke tests for packet construction.
- Kept MQTT transport disconnected from the production driver entry point pending protocol and Hub v2 runtime tests.

## 0.1.0-dev.1 - 2026-11-24

- Created a separate derivative project for the SmartThings Z-Wave Metering Switch driver.
- Documented target hardware, architecture, MQTT topic plan, and safety requirements.
- Preserved the upstream driver attribution and Apache-2.0 licensing notices.
- MQTT transport is not yet enabled in the production driver entry point.
