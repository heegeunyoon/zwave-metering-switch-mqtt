-- Z-Wave Metering Switch MQTT
-- Derived from Zwave Metering Switch ver 0.1.1
-- Copyright 2021 jido1517
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- MQTT integration is intentionally not connected in this initial commit.
-- This keeps the known-good Z-Wave behavior isolated until transport tests pass.

local capabilities = require "st.capabilities"
local defaults = require "st.zwave.defaults"
local ZwaveDriver = require "st.zwave.driver"
local Meter = (require "st.zwave.CommandClass.Meter")({ version = 3 })

local function momentary_reset_handler(_, device)
  device:send(Meter:Reset({}))
  device:refresh()
end

local function device_added(_, device)
  device:refresh()
end

local driver_template = {
  supported_capabilities = {
    capabilities.switch,
    capabilities.powerMeter,
    capabilities.energyMeter,
    capabilities.refresh,
    capabilities.momentary
  },
  lifecycle_handlers = {
    added = device_added
  },
  capability_handlers = {
    [capabilities.momentary.ID] = {
      [capabilities.momentary.commands.push.NAME] = momentary_reset_handler
    }
  },
  sub_drivers = {
    require "dawon-plug"
  }
}

defaults.register_for_default_handlers(driver_template, driver_template.supported_capabilities)

local driver = ZwaveDriver("zwave_metering_switch_mqtt", driver_template)
driver:run()
