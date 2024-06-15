--> NuiTerm/Event.lua
--
local NTEventDispatcher = require("NuiTerm.Events.EventDispatcher").NTEventDispatcher
local EventParameters   = require("NuiTerm.Events.EventParameters")
local EVENTS            = require("NuiTerm.Events.EventDispatcher").EVENTS
local NuiTermWindow     = require("NuiTerm.UI.MainWindow")
local TabBar            = require("NuiTerm.UI.TabBar.Bar")
local UIConfig          = require("NuiTerm.Config.Handler").UIConfig

---@class NTEventController
---@field dispatcher    NTEventDispatcher
---@field NuiTermWindow MainWindow
---@field NuiTermTabBar TabBar
---@field UIConfig      UIConfig
---@field paramters     EventParamters
local NTEventController={  }

---@param opts table
function NTEventController:new(opts)
  local obj = {
    dispatcher    = NTEventDispatcher:new(),
    NuiTermWindow = NuiTermWindow:new(),
    UIConfig      = UIConfig:new(opts),
    paramters     = EventParameters:new()
  }
  setmetatable(obj, self)
  return obj
end

function NTEventController:Initialize()
end

return NTEventController
