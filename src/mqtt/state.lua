-- MQTT state and Home Assistant discovery payloads.
local json = require "st.json"
local M = {}

local function safe_id(value)
  return (value:gsub("[^%w_%-]", "_"))
end

function M.topics(device)
  local id = safe_id(device.id)
  return {
    id = id,
    state = "stzwave/" .. id .. "/state",
    command = "stzwave/" .. id .. "/set",
    switch_config = "homeassistant/switch/" .. id .. "/config",
    power_config = "homeassistant/sensor/" .. id .. "_power/config",
    energy_config = "homeassistant/sensor/" .. id .. "_energy/config"
  }
end

function M.discovery(device, topics)
  local name = device.label or "Z-Wave Metering Plug"
  local base = {
    name = name,
    unique_id = topics.id,
    state_topic = topics.state,
    command_topic = topics.command,
    value_template = "{{ value_json.switch }}",
    payload_on = "ON",
    payload_off = "OFF",
    state_on = "ON",
    state_off = "OFF",
    device = {
      identifiers = { "smartthings_" .. topics.id },
      name = name,
      manufacturer = "Dawon / U+",
      model = "Z-Wave Metering Plug"
    }
  }
  local switch = {}
  for k, v in pairs(base) do switch[k] = v end
  local power = {
    name = name .. " Power",
    unique_id = topics.id .. "_power",
    state_topic = topics.state,
    value_template = "{{ value_json.power }}",
    unit_of_measurement = "W",
    device_class = "power",
    state_class = "measurement",
    device = base.device
  }
  local energy = {
    name = name .. " Energy",
    unique_id = topics.id .. "_energy",
    state_topic = topics.state,
    value_template = "{{ value_json.energy }}",
    unit_of_measurement = "kWh",
    device_class = "energy",
    state_class = "total_increasing",
    device = base.device
  }
  return json.encode(switch), json.encode(power), json.encode(energy)
end

return M
