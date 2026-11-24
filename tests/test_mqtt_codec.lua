local mqtt = require "mqtt.codec"

local connect = mqtt.connect("edge-test")
assert(connect:byte(1) == 0x10)
assert(connect:byte(2) == 16)

local pub = mqtt.publish("test/topic", "ON", true)
assert(pub:byte(1) == 0x31)

local sub = mqtt.subscribe(1, "test/+/set")
assert(sub:byte(1) == 0x82)

local ping = mqtt.pingreq()
assert(ping == string.char(0xC0, 0x00))

print("MQTT codec smoke tests passed")
