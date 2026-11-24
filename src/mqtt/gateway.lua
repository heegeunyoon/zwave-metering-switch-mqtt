-- Shared MQTT Gateway device lookup and provisioning.
local M = {}
M.DEVICE_NETWORK_ID = "stzwave-mqtt-gateway"
M.PROFILE = "mqtt-gateway"

function M.is_gateway(device)
  return device ~= nil and device.device_network_id == M.DEVICE_NETWORK_ID
end

function M.find(driver)
  for _, device in ipairs(driver:get_devices()) do
    if M.is_gateway(device) then return device end
  end
  return nil
end

function M.ensure(driver)
  if M.find(driver) or driver.mqtt_gateway_creation_requested then return true end
  driver.mqtt_gateway_creation_requested = true
  local metadata = {
    type = "LAN",
    device_network_id = M.DEVICE_NETWORK_ID,
    label = "MQTT Gateway",
    profile = M.PROFILE,
    manufacturer = "SmartThings Edge",
    model = "Shared MQTT Gateway",
    vendor_provided_label = "MQTT Gateway"
  }
  local ok, result, err = pcall(function()
    return driver:try_create_device(metadata)
  end)
  if not ok or result == false or result == nil then
    driver.mqtt_gateway_creation_requested = nil
    local reason = err or result
    log.warn("Unable to request MQTT Gateway creation: " .. tostring(reason))
    return nil, reason
  end
  log.info("Requested creation of the shared MQTT Gateway LAN device")
  return true
end

function M.get_preferences(driver)
  local gateway = M.find(driver)
  if not gateway then return nil, "MQTT Gateway device has not been created yet" end
  local prefs = gateway.preferences or {}
  local host = prefs.mqttBrokerHost
  if type(host) ~= "string" or host == "" then
    return nil, "Set the MQTT Broker Address in MQTT Gateway settings"
  end
  local port = tonumber(prefs.mqttBrokerPort) or 1883
  if port < 1 or port > 65535 then return nil, "MQTT Broker Port must be 1-65535" end
  local topic_prefix = prefs.mqttTopicPrefix or "stzwave"
  local discovery_prefix = prefs.haDiscoveryPrefix or "homeassistant"
  if topic_prefix:find("[+#]") or discovery_prefix:find("[+#]") then
    return nil, "MQTT topic prefixes cannot contain wildcard characters"
  end
  return {
    host = host, port = port, username = prefs.mqttUsername,
    password = prefs.mqttPassword, topic_prefix = topic_prefix,
    discovery_prefix = discovery_prefix
  }
end
return M
