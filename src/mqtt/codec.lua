-- MQTT 3.1.1 packet codec (QoS 0 publish path).
-- Copyright 2026 contributors.
-- Licensed under Apache-2.0; see LICENSE.

local M = {}

local function u16(value)
  assert(value >= 0 and value <= 65535, "uint16 out of range")
  return string.char(math.floor(value / 256), value % 256)
end

local function utf8_field(value)
  assert(type(value) == "string", "MQTT string must be a string")
  assert(not value:find("\\%z"), "MQTT UTF-8 strings cannot contain NUL")
  return u16(#value) .. value
end

local function remaining_length(value)
  assert(value >= 0 and value <= 268435455, "MQTT packet too large")
  local out = {}
  repeat
    local digit = value % 128
    value = math.floor(value / 128)
    if value > 0 then digit = digit + 128 end
    out[#out + 1] = string.char(digit)
  until value == 0
  return table.concat(out)
end

local function packet(header, body)
  return string.char(header) .. remaining_length(#body) .. body
end

function M.connect(client_id, username, password, keepalive)
  keepalive = keepalive or 60
  local flags = 0x02 -- clean session
  local payload = utf8_field(client_id)
  if username ~= nil and username ~= "" then
    flags = flags + 0x80
    payload = payload .. utf8_field(username)
  end
  if password ~= nil and password ~= "" then
    assert(username ~= nil and username ~= "", "MQTT password requires username")
    flags = flags + 0x40
    payload = payload .. utf8_field(password)
  end
  local variable = utf8_field("MQTT") .. string.char(4, flags) .. u16(keepalive)
  return packet(0x10, variable .. payload)
end

function M.publish(topic, payload, retain)
  local body = utf8_field(topic) .. (payload or "")
  return packet(retain and 0x31 or 0x30, body)
end

function M.subscribe(packet_id, topic)
  local body = u16(packet_id) .. utf8_field(topic) .. string.char(0)
  return packet(0x82, body)
end

function M.pingreq()
  return string.char(0xC0, 0x00)
end

function M.disconnect()
  return string.char(0xE0, 0x00)
end

function M.decode_publish(data)
  assert(type(data) == "string" and #data >= 4, "incomplete MQTT packet")
  local header = data:byte(1)
  assert(math.floor(header / 16) == 3, "not an MQTT PUBLISH packet")
  local multiplier, remaining, index = 1, 0, 2
  while true do
    local digit = data:byte(index)
    assert(digit ~= nil, "incomplete remaining length")
    remaining = remaining + (digit % 128) * multiplier
    index = index + 1
    if digit < 128 then break end
    multiplier = multiplier * 128
    assert(multiplier <= 128 * 128 * 128, "invalid remaining length")
  end
  assert(#data >= index + remaining - 1, "incomplete MQTT payload")
  local topic_len = data:byte(index) * 256 + data:byte(index + 1)
  index = index + 2
  local topic = data:sub(index, index + topic_len - 1)
  index = index + topic_len
  local qos = math.floor((header % 8) / 2)
  assert(qos == 0, "only QoS 0 inbound PUBLISH is supported")
  return {
    topic = topic,
    payload = data:sub(index, index + remaining - (index - (2 + (index - 2 - topic_len))) - 1),
    retain = (header % 2) == 1
  }
end

M._remaining_length = remaining_length
M._utf8_field = utf8_field
return M
