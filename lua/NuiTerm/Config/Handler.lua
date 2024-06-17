--> NuiTerm/Config/handlers.lua
--
local MergeConfig = require("NuiTerm.utils").MergeConfigs
local Defaults = require("NuiTerm.Config.Defaults")
local Utils    = require("NuiTerm.Config.Utils")

---@class NTConfigHandler
local NTConfigHandler = {}

---@param opts table
function NTConfigHandler:new(opts)
  local winconf = MergeConfig(Defaults.winConfig(), opts.win_config)
  local keymaps = MergeConfig(Defaults.keymaps(), opts.keymaps)

  ---TODO: Add tabbar_conf to user-defined settings: Colors, length, position, etc..
  local tabConf = Utils.NuitermTabBarConfig(opts.win_config)

  local obj = {
    window  = Utils.NuiTermWindowConfig(winconf),
    tabBar  = tabConf.MainBar,
    tab     = tabConf.Tab,
    keymaps = keymaps,
  }
  setmetatable(obj, self)
  return obj
end


-- UICONFIG = NTConfigHandler:new()
return NTConfigHandler
