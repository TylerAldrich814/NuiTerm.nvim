--> NuiTerm/Config/handlers.lua
--
local MergeConfig = require("NuiTerm.utils").MergeConfigs
local Defaults = require("NuiTerm.Config.Defaults")
local Utils    = require("NuiTerm.Config.Utils")

---@class UIConfig
---@field window table
---@field tabBar table
---@field tab    table
local UIConfig = {}

---@param opts table
function UIConfig:new(opts)
  local winconf = MergeConfig(Defaults.winConfig(), opts.win_config)

  ---TODO: Add tabbar_conf to user-defined settings: Colors, length, position, etc..
  local tabConf = Utils.NuitermTabBarConfig(opts.win_config)

  local obj = {
    window = Utils.NuiTermWindowConfig(winconf),
    tabBar = tabConf.MainBar,
    tab    = tabConf.Tab,

  }
  setmetatable(obj, self)
  return obj
end

-- UICONFIG = UIConfig:new()
return { UIConfig = UIConfig }
