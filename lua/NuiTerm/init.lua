--> NuiTerm/init.lua
--
local NuiTerm         = require("NuiTerm.UI.MainWindow")
local UserKeyCommands = require("NuiTerm.Keymap.userCmds")
local NuiTermSetup    = require("NuiTerm.setup")
local NTEventDispatcher = require("NuiTerm.Events.EventDispatcher").NTEventDispatcher

local M = {}
M.keyMaps = NuiTermSetup.keyMaps

M.setup = function(opts)
  M.keyMaps = opts.user_keymaps
  NuiTermSetup.setup(opts)
  local winConfig = NuiTermSetup.WindowConfig(opts.win_config)
  if not winConfig.relative then
    error("Relative is missing", 2)
  end

  local tabBarConfig = NuiTermSetup.TabBarConfig(opts.win_config)

  M.MainWindow = NuiTerm:new(winConfig, tabBarConfig)

  vim.keymap.set(
    'n',
    M.keyMaps.nuiterm_toggle,
    function()
      M.MainWindow:Toggle()
    end,
    {
      noremap = true,
      silent  = true,
    }
  )
  vim.keymap.set(
    'n',
    M.keyMaps.new_term,
    function()
      M.MainWindow:NewTerm()
    end,
    {
      noremap = true,
      silent  = true,
    }
  )
end

M.Expand = function()
  M.MainWindow:Resize(NuiTermSetup.keyMaps.term_resize.expand.amt)
end
M.Shrink = function()
  M.MainWindow:Resize(NuiTermSetup.keyMaps.term_resize.shrink.amt)
end

UserKeyCommands.UserCommandSetup(M)

return M
