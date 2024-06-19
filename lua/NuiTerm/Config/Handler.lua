--> NuiTerm/Config/handlers.lua
--
local MergeConfig = require("NuiTerm.utils").MergeConfigs
local Defaults    = require("NuiTerm.Config.Defaults")
local Utils       = require("NuiTerm.Config.Utils")

local log = require("NuiTerm.Debug").LOG_FN("NTConfigHandler", {
  deactivated = false
})

---@class NTConfigHandler
local NTConfigHandler = {}

---@param opts table
function NTConfigHandler:new(opts)
  local winconf = MergeConfig(Defaults.winConfig(), opts.win_config)
  local padding = winconf.padding

  local mainWindowConfig = Utils.NuiTermMainWindowConfig(winconf)

  local shellConfig = Utils.NuiTermShellConfig(mainWindowConfig, padding)
  local keymaps = MergeConfig(Defaults.keymaps(), opts.keymaps)

  ---TODO: Add tabbar_conf to user-defined settings: Colors, length, position, etc..
  local tabConf = Utils.NuitermTabBarConfig(opts.win_config)

  local obj = setmetatable({
    ops     = opts,
    window  = Utils.NuiTermMainWindowConfig(winconf),
    tabBar  = tabConf.MainBar,
    tab     = tabConf.Tab,
    shell   = shellConfig,
    keymaps = keymaps,
  }, {__index = self})
  return obj
end

return NTConfigHandler
