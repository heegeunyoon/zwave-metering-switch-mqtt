-- MQTT 3.1.1 QoS 0 client for SmartThings Edge.
-- All sockets must be created through cosock.socket.
local cosock = require "cosock"
local socket = cosock.socket
local codec = require "mqtt.codec"

local Client = {}
Client.__index = Client

function Client.new(opts)
  return setmetatable({ opts = opts, sock = nil, connected = false, packet_id = 1, rx = "" }, Client)
end

function Client:close()
  if self.sock then
    pcall(function() self.sock:send(codec.disconnect()) end)
    pcall(function() self.sock:close() end)
  end
  self.sock, self.connected, self.rx = nil, false, ""
end

function Client:connect()
  self:close()
  local sock = socket.tcp()
  sock:settimeout(self.opts.timeout or 5)
  local ok, err = sock:connect(self.opts.host, self.opts.port or 1883)
  if not ok then pcall(function() sock:close() end); return nil, err end

  local sent, send_err = sock:send(codec.connect(
    self.opts.client_id, self.opts.username, self.opts.password, self.opts.keepalive or 60))
  if not sent then pcall(function() sock:close() end); return nil, send_err end

  local first, read_err = sock:receive(1)
  if not first then pcall(function() sock:close() end); return nil, read_err or "CONNACK timeout" end
  local second, read_err2 = sock:receive(1)
  if not second then pcall(function() sock:close() end); return nil, read_err2 or "CONNACK incomplete" end
  local rest, read_err3 = sock:receive(2)
  if not rest then pcall(function() sock:close() end); return nil, read_err3 or "CONNACK incomplete" end
  if first:byte(1) ~= 0x20 or second:byte(1) ~= 0x02 or rest:byte(2) ~= 0 then
    pcall(function() sock:close() end)
    return nil, "broker rejected MQTT CONNECT"
  end

  self.sock, self.connected, self.rx = sock, true, ""
  sock:settimeout(1)
  return true
end

function Client:send_packet(packet)
  if not self.connected or not self.sock then return nil, "not connected" end
  local sent, err = self.sock:send(packet)
  if not sent then self:close(); return nil, err end
  return true
end

function Client:publish(topic, payload, retain)
  return self:send_packet(codec.publish(topic, payload, retain))
end

function Client:subscribe(topic)
  local id = self.packet_id
  self.packet_id = (self.packet_id % 65535) + 1
  return self:send_packet(codec.subscribe(id, topic))
end

-- Read available bytes without assuming TCP packet boundaries.
-- A timeout may return a partial string; it is always appended to the stream buffer.
function Client:read_messages()
  if not self.connected or not self.sock then return nil, "not connected" end
  local data, err, partial = self.sock:receive(4096)
  if data then self.rx = self.rx .. data
  elseif partial and #partial > 0 then self.rx = self.rx .. partial end

  local messages = {}
  while #self.rx > 0 do
    local packet, consumed, parse_err = codec.take_packet(self.rx)
    if parse_err then self:close(); return nil, parse_err end
    if not packet then break end
    self.rx = self.rx:sub(consumed + 1)
    local kind = math.floor(packet:byte(1) / 16)
    if kind == 3 then
      local ok, decoded = pcall(codec.decode_publish, packet)
      if not ok then self:close(); return nil, decoded end
      messages[#messages + 1] = decoded
    end
  end
  if err and err ~= "timeout" and err ~= "closed" then self:close(); return nil, err end
  if err == "closed" then self:close(); return nil, "broker closed connection" end
  return messages
end

return Client
