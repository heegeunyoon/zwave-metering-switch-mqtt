# MQTT integration test plan

## Current implementation boundary

The MQTT client is an experimental MQTT 3.1.1 QoS 0 transport using SmartThings Edge `cosock.socket`. It is not enabled by default and must not be installed on the production Hub v2 yet.

## Broker prerequisites

1. Run Mosquitto on the Docker VM.
2. Bind the listener to the server LAN interface only.
3. Configure a dedicated username/password.
4. Restrict TCP/1883 to the SmartThings Hub and HA networks with the UDM firewall.
5. Do not expose this listener to the internet.

## Test sequence

1. Verify the hub can open a TCP connection to the broker.
2. Verify MQTT CONNECT / CONNACK.
3. Verify retained QoS 0 PUBLISH.
4. Verify SUBSCRIBE and inbound PUBLISH parsing.
5. Verify HA MQTT Discovery payloads.
6. Verify switch command routing to the existing Z-Wave capability handler.
7. Verify power/energy state publishing.
8. Verify broker restart, hub restart, and network interruption recovery.

## Important limitations

- This transport currently implements MQTT 3.1.1 QoS 0 only.
- The reconnect supervisor and device-event integration are not enabled.
- Inbound PUBLISH parsing currently assumes complete packets are available in one non-blocking read; TCP may split packets, so a buffered stream parser is required before real deployment.
- The current code is a development scaffold, not a release candidate.
