local mqtt = require "mqtt.codec"

local connect = mqtt.connect("edge-test", "user", "secret", 60)
assert(connect:byte(1) == 0x10)

local pub = mqtt.publish("test/topic", "ON", true)
assert(pub:byte(1) == 0x31)
local decoded = mqtt.decode_publish(pub)
assert(decoded.topic == "test/topic")
assert(decoded.payload == "ON")
assert(decoded.retain == true)

-- Verify TCP stream framing when the MQTT packet arrives in fragments.
local first = pub:sub(1, 3)
local second = pub:sub(4)
local packet = mqtt.take_packet(first)
assert(packet == nil, "partial MQTT packet must not be decoded")
local combined = first .. second
local framed, consumed = mqtt.take_packet(combined)
assert(framed == pub)
assert(consumed == #pub)
assert(mqtt.decode_publish(framed).payload == "ON")

local sub = mqtt.subscribe(1, "test/+/set")
assert(sub:byte(1) == 0x82)
assert(mqtt.pingreq() == string.char(0xC0, 0x00))

print("MQTT codec and stream framing tests passed")
