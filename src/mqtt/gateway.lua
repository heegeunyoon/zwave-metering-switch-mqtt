-- Shared MQTT Gateway device lookup and provisioning.
-- The Gateway is a LAN virtual device owned by this Edge driver package.
-- Broker settings are stored only in gateway.preferences.
local M = {}

M.DEVICE_NETWORK_ID = "stzwave-mqtt-gateway"
M.PROFILE = "mqtt-gateway"

function M.is_gateway(device)
  return device ~= nil and device.device_network_id == M.DEVICE_NETWORK_ID
end

function M.find(driver)
  for _, device in ipairs(driver:get_devices()) do
    if M.is_gateway(device) then
      return device
    end
  end
  return nil
end

function M.ensure(driver)
  if M.find(driver) then
    return true
  end

  -- Multiple Z-Wave devices may receive init at startup. Guard against
  -- sending duplicate LAN-device creation requests from the same driver.
  if driver.mqtt_gateway_creation_requested then
    return true
  end
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

  local ok, err = pcall(function()
    driver:try_create_device(metadata)
  end)

  if not ok then
    driver.mqtt_gateway_creation_requested = nil
    log.warn("Unable to request MQTT Gateway creation: " .. tostring(err))
    return nil, err
  end

  log.info("Requested creation of the shared MQTT Gateway LAN device")
  return true
end

function M.get_preferences(driver)
  local gateway = M.find(driver)
  if not gateway then
    return nil, "MQTT Gateway device has not been created yet"
  end

  local prefs = gateway.preferences or {}
  local host = prefs.mqttBrokerHost
  if type(host) ~= "string" or host == "" then
    return nil, "Set the MQTT Broker Address in MQTT Gateway settings"
  end

  return {
    host = host,
    port = tonumber(prefs.mqttBrokerPort) or 1883,
    username = prefs.mqttUsername,
    password = prefs.mqttPassword,
    topic_prefix = prefs.mqttTopicPrefix or "stzwave",
    discovery_prefix = prefs.haDiscoveryPrefix or "homeassistant"
  }
end

return M
