--> NuiTerm/init.lua
--
local setup = require("NuiTerm.setup")
local nuiterm = require("NuiTerm.MainWindow")


local M = {}
M.setup = setup.setup

M.MoveCursorDir = function(dir)
  vim.cmd('wincmd ' .. dir)
end

M.setup = function(opts)
  M.opts = opts
end
M.MainWindow = nuiterm.MainWindow:New()

-- vim.keymap.set('n', setup.keyMaps.move_up,    function() M.MoveCursorDir('k') end)
-- vim.keymap.set('n', setup.keyMaps.move_down,  function() M.MoveCursorDir('j') end)
-- vim.keymap.set('n', setup.keyMaps.move_left,  function() M.MoveCursorDir('h') end)
-- vim.keymap.set('n', setup.keyMaps.move_right, function() M.MoveCursorDir('l') end)


vim.keymap.set(
  'n',
  setup.keyMaps.nuiterm_toggle,
  function()
    M.MainWindow:Toggle()
  end,
  {
    noremap = true,
    silent  = true,
  }
)

return M
