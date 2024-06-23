--> NuiTerm/init.lua
--
local NTEventController = require("NuiTerm.Events.EventController")

local M = {}

M.setup = function(opts)
  local eventController = NTEventController:new(opts)
  eventController:PushSubscriptions()
  eventController:GlobalAutoCmds()
  eventController:SetupUserCmds()

  M.eventController = eventController
end

M.Expand = function()
  error("NuiTerm Expand needs implemented! Remember to update keymap/term.lua keymap")
end
M.Shrink = function()
  error("NuiTerm Shrink needs implemented! Remember to update keymap/term.lua keymap")
end

return M
