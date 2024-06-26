--> NuiTerm/Config/handlers.lua
--
local MergeConfig = require("NuiTerm.utils").MergeConfigs
local Defaults    = require("NuiTerm.Config.Defaults")
local Utils       = require("NuiTerm.Config.Utils")
local NuitermDB   = require("NuiTerm.sql.db")

local log = require("NuiTerm.Debug").LOG_FN("NTConfigHandler", {
  deactivated = true
})

---@class NTConfigHandler
local NTConfigHandler = {}

---@param opts table
function NTConfigHandler:new(opts)
  local nuiterm_dbConfig = opts.nuiterm_db
  local nuiterm_db = nil
  -- if nuiterm_dbConfig then
  --   nuiterm_db = NuitermDB:new(nuiterm_dbConfig)
  -- end

  local winconf = MergeConfig(Defaults.winConfig(), opts.win_config)
  local padding = Defaults.MainWindowPadding

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
