--> NuiTerm/init.lua
--
local NuiTermSetup  = require("NuiTerm.setup")
local NuiTerm       = require("NuiTerm.UI.MainWindow")
local Debug         = require("NuiTerm.Debug")

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

  M.MainWindow = NuiTerm.MainWindow:New(winConfig, tabBarConfig)

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

for _, cmd in pairs({
  {
    cmd = "DebugShow",
    fn = function() Debug.create_or_get_debug_window() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "DebugHide",
    fn = function() Debug.hide_debug_window() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "DebugToggle",
    fn = function() Debug.ToggleDebug() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "ToggleWindow",
    fn  = function() M.MainWindow:Toggle() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "ShowWindow",
    fn  = function() M.MainWindow:Show() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "HideWindow",
    fn  = function() M.MainWindow:Hide() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "Resize",
    fn = function(opts) M.MainWindow:Resize(opts.args) end,
    opts = { nargs = 1 },
  },
  {
    cmd = "NewTerm",
    fn  = function() M.MainWindow:NewTerm() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "DelTerm",
    fn  = function(opts)
      local term_id = tonumber(opts.args)
      if term_id then
        M.MainWindow:DeleteTerm(term_id)
      end
    end,
    opts = { nargs = 1 }
  },
  {
    cmd = "DeleteCurrentTerm",
    fn  = function() M.MainWindow:DeleteTerm(nil) end,
    opts = { nargs = 1 }
  },
  {
    cmd = "ToTerm",
    fn = function(opts)
      local term_id = tonumber(opts.args)
      M.MainWindow:ToTerm(term_id)
    end,
    opts = { nargs = 1 }
  },
  {
    cmd = "NextTerm",
    fn  = function() M.MainWindow:NextTerm() end,
    opts = { nargs = 0 }
  },
  {
    cmd = "PrevTerm",
    fn  = function() M.MainWindow:PrevTerm() end,
    opts = { nargs = 0 }
  },
}) do
  vim.api.nvim_create_user_command("NuiTerm"..cmd.cmd, cmd.fn, cmd.opts)
end

return M
