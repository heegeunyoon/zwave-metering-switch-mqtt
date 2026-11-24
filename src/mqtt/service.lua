-- Shared MQTT connection supervisor for all Z-Wave plugs in this driver.
-- MQTT settings are read only from the single LAN MQTT Gateway device.
local cosock = require "cosock"
local socket = cosock.socket
local Client = require "mqtt.client"
local State = require "mqtt.state"
local Gateway = require "mqtt.gateway"
local Codec = require "mqtt.codec"
local log = require "log"

local M = {}
local generation = 0
local running = false

local function wait(seconds)
  socket.select({}, {}, seconds)
end

local function plugs(driver)
  local result = {}
  for _, device in ipairs(driver:get_devices()) do
    if not Gateway.is_gateway(device)
      and device:supports_capability_by_id("switch", "main") then
      result[#result + 1] = device
    end
  end
  return result
end

local function publish_discovery(client, device, prefs)
  local topics = State.topics(device, prefs.topic_prefix, prefs.discovery_prefix)
  local switch, power, energy = State.discovery(device, topics)
  return client:publish(topics.switch_config, switch, true)
    and client:publish(topics.power_config, power, true)
    and client:publish(topics.energy_config, energy, true)
end

local function publish_states(client, driver, prefs)
  for _, device in ipairs(plugs(driver)) do
    local payload = State.state_payload(device)
    if payload then
      local topics = State.topics(device, prefs.topic_prefix, prefs.discovery_prefix)
      local ok, err = client:publish(topics.state, payload, true)
      if not ok then return nil, err end
    end
  end
  return true
end

local function handle_message(driver, prefs, message)
  local prefix = prefs.topic_prefix .. "/"
  if message.topic:sub(1, #prefix) ~= prefix then return end
  local device_id, suffix = message.topic:sub(#prefix + 1):match("^([^/]+)/([^/]+)$")
  if not device_id or suffix ~= "set" then return end

  local requested = message.payload:upper()
  local command = (requested == "ON" and "on") or (requested == "OFF" and "off")
  if not command then
    log.warn("Ignoring unsupported MQTT switch payload: " .. tostring(message.payload))
    return
  end

  for _, device in ipairs(plugs(driver)) do
    local topics = State.topics(device, prefs.topic_prefix, prefs.discovery_prefix)
    if topics.id == device_id then
      driver:inject_capability_command(device, {
        component = "main", capability = "switch", command = command, args = {}
      })
      return
    end
  end
end

local function run_worker(driver, prefs, worker_generation)
  local retry = 2
  local client_id = "st-edge-" .. tostring(Gateway.DEVICE_NETWORK_ID)
  while generation == worker_generation do
    local client = Client.new({
      host = prefs.host, port = prefs.port, username = prefs.username,
      password = prefs.password, client_id = client_id,
      keepalive = 60, timeout = 8
    })
    local connected, err = client:connect()
    if connected then
      log.info("Connected to configured MQTT broker")
      retry = 2
      local subscribed, sub_err = client:subscribe(prefs.topic_prefix .. "/+/set")
      if not subscribed then
        log.warn("MQTT subscribe failed: " .. tostring(sub_err))
        client:close()
      else
        local discovered = {}
        local last_state, last_ping = 0, os.time()
        while generation == worker_generation and client.connected do
          local messages, read_err = client:read_messages()
          if not messages then
            if read_err ~= "timeout" then log.warn("MQTT receive failed: " .. tostring(read_err)) end
            break
          end
          for _, message in ipairs(messages) do handle_message(driver, prefs, message) end

          local now = os.time()
          for _, device in ipairs(plugs(driver)) do
            if not discovered[device.id] then
              local ok, publish_err = publish_discovery(client, device, prefs)
              if not ok then
                log.warn("MQTT discovery publish failed: " .. tostring(publish_err))
                client:close()
                break
              end
              discovered[device.id] = true
            end
          end
          if not client.connected then break end

          if now - last_state >= 5 then
            local ok, publish_err = publish_states(client, driver, prefs)
            if not ok then
              log.warn("MQTT state publish failed: " .. tostring(publish_err))
              break
            end
            last_state = now
          end
          if now - last_ping >= 25 then
            local ping_ok, ping_err = client:send_packet(Codec.pingreq())
            if not ping_ok then
              log.warn("MQTT keepalive failed: " .. tostring(ping_err))
              break
            end
            last_ping = now
          end
        end
      end
    else
      log.warn("MQTT connection failed: " .. tostring(err))
    end
    client:close()
    if generation == worker_generation then
      wait(retry)
      retry = math.min(retry * 2, 60)
    end
  end
  log.info("MQTT worker stopped")
end

function M.start(driver, _gateway)
  local prefs, err = Gateway.get_preferences(driver)
  if not prefs then log.warn(err); return nil, err end
  local signature = table.concat({
    prefs.host, tostring(prefs.port), prefs.username or "",
    prefs.password or "", prefs.topic_prefix, prefs.discovery_prefix
  }, "|")
  if driver.mqtt_signature == signature and running then return true end

  generation = generation + 1
  local worker_generation = generation
  driver.mqtt_signature = signature
  running = true
  cosock.spawn(function()
    while generation == worker_generation do
      local ok, worker_err = pcall(run_worker, driver, prefs, worker_generation)
      if not ok then
        log.error("MQTT supervisor recovered from runtime error: " .. tostring(worker_err))
        if generation == worker_generation then wait(5) end
      end
    end
    if generation == worker_generation then running = false end
  end, "shared-mqtt-gateway")
  log.info("Started shared MQTT Gateway worker")
  return true
end

function M.stop(driver)
  generation = generation + 1
  running = false
  driver.mqtt_signature = nil
end
return M
