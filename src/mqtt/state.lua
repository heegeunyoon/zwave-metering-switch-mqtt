-- MQTT topic and Home Assistant discovery/state helpers.
local json = require "st.json"
local M = {}

local function safe_id(value)
  return tostring(value):gsub("[^%w_%-]", "_")
end

function M.topics(device, topic_prefix, discovery_prefix)
  local id = safe_id(device.id)
  topic_prefix, discovery_prefix = topic_prefix or "stzwave", discovery_prefix or "homeassistant"
  return {
    id = id, state = topic_prefix .. "/" .. id .. "/state",
    command = topic_prefix .. "/" .. id .. "/set",
    switch_config = discovery_prefix .. "/switch/" .. id .. "/config",
    power_config = discovery_prefix .. "/sensor/" .. id .. "_power/config",
    energy_config = discovery_prefix .. "/sensor/" .. id .. "_energy/config"
  }
end

function M.discovery(device, topics)
  local name = device.label or "Z-Wave Metering Plug"
  local device_info = {
    identifiers = { "smartthings_" .. topics.id }, name = name,
    manufacturer = "Dawon / U+", model = "Z-Wave Metering Plug"
  }
  local _, energy_state = device:get_latest_state("main", "energyMeter", "energy")
  local energy_unit = (energy_state and energy_state.unit) or "kWh"
  return
    json.encode({
      name = name, unique_id = topics.id, state_topic = topics.state,
      command_topic = topics.command, value_template = "{{ value_json.switch }}",
      payload_on = "ON", payload_off = "OFF", state_on = "ON", state_off = "OFF",
      device = device_info
    }),
    json.encode({
      name = name .. " Power", unique_id = topics.id .. "_power",
      state_topic = topics.state, value_template = "{{ value_json.power }}",
      unit_of_measurement = "W", device_class = "power", state_class = "measurement",
      device = device_info
    }),
    json.encode({
      name = name .. " Energy", unique_id = topics.id .. "_energy",
      state_topic = topics.state, value_template = "{{ value_json.energy }}",
      unit_of_measurement = energy_unit, device_class = "energy",
      state_class = "total_increasing", device = device_info
    })
end

function M.state_payload(device)
  local switch = device:get_latest_state("main", "switch", "switch")
  local power = device:get_latest_state("main", "powerMeter", "power")
  local energy, energy_state = device:get_latest_state("main", "energyMeter", "energy")
  if switch == nil and power == nil and energy == nil then return nil end
  local payload = {
    switch = (switch == "on") and "ON" or ((switch == "off") and "OFF" or nil),
    power = tonumber(power), energy = tonumber(energy)
  }
  if energy_state and energy_state.unit then payload.energy_unit = energy_state.unit end
  return json.encode(payload)
end
return M
