-- Copyright 2021 SmartThings
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

local Configuration = (require "st.zwave.CommandClass.Configuration")({ version = 1 })

local DAWON_FINGERPRINTS = {
  {mfr = 0x018C, prod = 0x0042, model = 0x0001}, -- UPlus SPES-01A 10A
  {mfr = 0x018C, prod = 0x0042, model = 0x0002}, -- UPlus SPES-01 10A
  {mfr = 0x018C, prod = 0x0042, model = 0x0003}, -- UPlus SPES-01 10A
  {mfr = 0x018C, prod = 0x0042, model = 0x0004}, -- UPlus SPES-01 10A
  {mfr = 0x018C, prod = 0x0042, model = 0x0005}, -- US Ver plug
  {mfr = 0x018C, prod = 0x0042, model = 0x0006}, -- KT PM-B400ZW-N 16A
  {mfr = 0x018C, prod = 0x0042, model = 0x0007}, -- UPlus SPD-02A / MTD-01 / KT models
  {mfr = 0x018C, prod = 0x0042, model = 0x0008}, -- US Ver Multitab
  {mfr = 0x0247, prod = 0x0042, model = 0x0002}, -- UPlus SPES-02A 16A
  {mfr = 0x0247, prod = 0x0042, model = 0x0001}  -- UPlus SPES-02 16A
}

local function can_handle_dawon_plug(_, _, device)
  for _, fingerprint in ipairs(DAWON_FINGERPRINTS) do
    if device:id_match(fingerprint.mfr, fingerprint.prod, fingerprint.model) then
      return true
    end
  end
  return false
end

local function do_configure(_, device)
  -- Preserve upstream behavior: request energy reporting every 10 minutes.
  device:send(Configuration:Set({
    parameter_number = 5,
    size = 1,
    configuration_value = 1
  }))
end

return {
  lifecycle_handlers = {
    doConfigure = do_configure
  },
  NAME = "dawon plug",
  can_handle = can_handle_dawon_plug
}
