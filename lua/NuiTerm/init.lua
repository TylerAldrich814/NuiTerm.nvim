--> NuiTerm/init.lua
--
local NuiTermSetup  = require("NuiTerm.setup")
local NuiTermUtils  = require("NuiTerm.utils")
local NuiTerm       = require("NuiTerm.UI.MainWindow")
local Debug         = require("NuiTerm.Debug")

local M = {}
-- M.setup = setup.setup

-- M.MoveCursorDir = function(dir)
--   vim.cmd('wincmd ' .. dir)
-- end

M.setup = function(opts)
  M.keyMaps = opts.user_keymaps
  NuiTermSetup.setup(opts)
  local winConfig = NuiTermUtils.WindowConfig(opts.win_config)
  if not winConfig.relative then
    error("Relative is missing", 2)
  end
  local tabBarConfig = NuiTermUtils.TabBarConfig(opts.win_config)
  if not tabBarConfig then
    error("tabBarConfig is fucked", 2)
  end
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
    {'n', 't'},
    '<leader>tl',
    function()
      M.MainWindow:NextTerm()
    end,
    {
      noremap = true,
      silent  = true,
    }
  )
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
