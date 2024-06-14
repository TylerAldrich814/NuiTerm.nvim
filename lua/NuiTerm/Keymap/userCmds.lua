--> NuiTerm/Keymap/userCmds.lua
--

local Debug = require("NuiTerm.Debug")
local M = {}

M.UserCommandSetup = function(GLOBAL)
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
      fn  = function() GLOBAL.MainWindow:Toggle() end,
      opts = { nargs = 0 }
    },
    {
      cmd = "ShowWindow",
      fn  = function() GLOBAL.MainWindow:Show() end,
      opts = { nargs = 0 }
    },
    {
      cmd = "HideWindow",
      fn  = function() GLOBAL.MainWindow:Hide() end,
      opts = { nargs = 0 }
    },
    {
      cmd = "Resize",
      fn = function(opts) GLOBAL.MainWindow:Resize(opts.args) end,
      opts = { nargs = 1 },
    },
    {
      cmd = "NewTerm",
      fn  = function() GLOBAL.MainWindow:NewTerm() end,
      opts = { nargs = 0 }
    },
    {
      cmd = "DelTerm",
      fn  = function(opts)
        local term_id = tonumber(opts.args)
        if term_id then
          GLOBAL.MainWindow:DeleteTerm(term_id)
        end
      end,
      opts = { nargs = 1 }
    },
    {
      cmd = "DeleteCurrentTerm",
      fn  = function() GLOBAL.MainWindow:DeleteTerm(nil) end,
      opts = { nargs = 1 }
    },
    {
      cmd = "ToTerm",
      fn = function(opts)
        local term_id = tonumber(opts.args)
        GLOBAL.MainWindow:ToTerm(term_id)
      end,
      opts = { nargs = 1 }
    },
    {
      cmd = "NextTerm",
      fn  = function() GLOBAL.MainWindow:NextTerm() end,
      opts = { nargs = 0 }
    },
    {
      cmd = "PrevTerm",
      fn  = function() GLOBAL.MainWindow:PrevTerm() end,
      opts = { nargs = 0 }
    },
  }) do
    vim.api.nvim_create_user_command("NuiTerm"..cmd.cmd, cmd.fn, cmd.opts)
  end
end

return M
