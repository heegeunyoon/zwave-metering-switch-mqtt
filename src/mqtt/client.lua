-- Minimal MQTT 3.1.1 QoS 0 client for SmartThings Edge.
-- Uses cosock.socket only. Experimental: test on a spare hub/device first.
local cosock = require "cosock"
local socket = cosock.socket
local codec = require "mqtt.codec"

local Client = {}
Client.__index = Client

local function read_packet(sock, timeout)
  sock:settimeout(timeout or 0)
  local first, err = sock:receive(1)
  if not first then return nil, err end

  local multiplier, remaining = 1, 0
  local encoded = {}
  repeat
    local byte, read_err = sock:receive(1)
    if not byte then return nil, read_err end
    local digit = byte:byte(1)
    encoded[#encoded + 1] = byte
    remaining = remaining + (digit % 128) * multiplier
    multiplier = multiplier * 128
    if multiplier > 128 * 128 * 128 then return nil, "invalid remaining length" end
    if digit < 128 then break end
  until false

  local body = ""
  if remaining > 0 then
    local data, body_err = sock:receive(remaining)
    if not data then return nil, body_err end
    body = data
  end
  return first .. table.concat(encoded) .. body
end

function Client.new(opts)
  return setmetatable({
    opts = opts,
    sock = nil,
    connected = false,
    packet_id = 1,
    rx = ""
  }, Client)
end

function Client:close()
  if self.sock then pcall(function() self.sock:close() end) end
  self.sock = nil
  self.connected = false
end

function Client:connect()
  self:close()
  local sock = socket.tcp()
  sock:settimeout(self.opts.timeout or 5)
  local ok, err = sock:connect(self.opts.host, self.opts.port or 1883)
  if not ok then
    -- cosock socket operations yield on timeout; a remaining timeout is a real failure here.
    pcall(function() sock:close() end)
    return nil, err or "connect failed"
  end

  local packet = codec.connect(
    self.opts.client_id,
    self.opts.username,
    self.opts.password,
    self.opts.keepalive or 60
  )
  local sent, send_err = sock:send(packet)
  if not sent then
    pcall(function() sock:close() end)
    return nil, send_err or "CONNECT send failed"
  end

  local response, response_err = read_packet(sock, self.opts.timeout or 5)
  if not response then
    pcall(function() sock:close() end)
    return nil, response_err or "CONNACK timeout"
  end
  if response:byte(1) ~= 0x20 or response:byte(#response) ~= 0 then
    pcall(function() sock:close() end)
    return nil, "broker rejected MQTT CONNECT"
  end

  self.sock = sock
  self.connected = true
  return true
end

function Client:publish(topic, payload, retain)
  if not self.connected or not self.sock then return nil, "not connected" end
  self.sock:settimeout(self.opts.timeout or 5)
  local sent, err = self.sock:send(codec.publish(topic, payload, retain))
  if not sent then self:close(); return nil, err end
  return true
end

function Client:subscribe(topic)
  if not self.connected or not self.sock then return nil, "not connected" end
  local id = self.packet_id
  self.packet_id = (self.packet_id % 65535) + 1
  self.sock:settimeout(self.opts.timeout or 5)
  local sent, err = self.sock:send(codec.subscribe(id, topic))
  if not sent then self:close(); return nil, err end
  return true
end

-- Non-blocking poll. Returns decoded PUBLISH packets; caller routes commands.
function Client:poll()
  if not self.connected or not self.sock then return nil, "not connected" end
  local packet, err = read_packet(self.sock, 0)
  if not packet then
    if err ~= "timeout" then self:close() end
    return nil, err
  end
  local kind = math.floor(packet:byte(1) / 16)
  if kind == 3 then
    return codec.decode_publish(packet)
  end
  return { control_packet = kind }
end

return Client
