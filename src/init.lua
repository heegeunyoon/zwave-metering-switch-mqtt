-- Z-Wave Metering Switch MQTT
-- Derived from Zwave Metering Switch ver 0.1.1
-- Copyright 2021 jido1517
-- Licensed under the Apache License, Version 2.0. See LICENSE.
local capabilities = require "st.capabilities"
local defaults = require "st.zwave.defaults"
local ZwaveDriver = require "st.zwave.driver"
local Meter = (require "st.zwave.CommandClass.Meter")({ version = 3 })
local Gateway = require "mqtt.gateway"
local MQTT = require "mqtt.service"

local function momentary_reset_handler(_, device)
  device:send(Meter:Reset({}))
  device:refresh()
end

local function device_added(_, device)
  if not Gateway.is_gateway(device) then device:refresh() end
end

local function device_init(driver, device)
  if Gateway.is_gateway(device) then
    MQTT.start(driver, device)
  else
    Gateway.ensure(driver)
  end
end

local function device_info_changed(driver, device)
  if Gateway.is_gateway(device) then MQTT.start(driver, device) end
end

local function device_removed(driver, device)
  if Gateway.is_gateway(device) then MQTT.stop(driver) end
end

local function gateway_refresh(driver, device)
  if Gateway.is_gateway(device) then
    MQTT.stop(driver)
    MQTT.start(driver, device)
  end
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch, capabilities.powerMeter, capabilities.energyMeter,
    capabilities.refresh, capabilities.momentary
  },
  lifecycle_handlers = {
    added = device_added,
    init = device_init,
    infoChanged = device_info_changed,
    removed = device_removed
  },
  capability_handlers = {
    [capabilities.momentary.ID] = {
      [capabilities.momentary.commands.push.NAME] = momentary_reset_handler
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = gateway_refresh
    }
  },
  driver_lifecycle = function(driver, event)
    if event == "shutdown" then MQTT.stop(driver) end
  end,
  sub_drivers = { require "dawon-plug" }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)
local driver = ZwaveDriver("zwave_metering_switch_mqtt", driver_template)
driver:run()
