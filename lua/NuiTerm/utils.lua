--> NuiTerm/utils.lua
--

local M = {}
local Debug = require("NuiTerm.Debug").Debug

M.GetTermSize = function()
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

M.WindowConfig = function(config)
  if not config then
    error("CONFIG IS NIL", 2)
  end
  local width    = config.width or vim.o.columns
  local height   = config.height or 20
  local position = config.position or "bottom"
  local style    = config.style or "minimal"
  local border   = config.border or "rounded"
  local row, col = 0, 0

  if position == "bottom" then
    row = vim.o.lines - height - 4
  elseif position == "top" then
    row = 4
  else
    error("\n     - NuiTerm: setup.position --> Found an unknown value - \"" .. position .. "\"")
  end

  return {
    relative = "editor",
    width    = width,
    height   = height,
    style    = style,
    border   = border,
    row      = row,
    col      = col
  }
end

M.TabBarConfig = function(config)
  local winWidth    = config.width or vim.o.columns
  local winHeight   = config.height or 20
  local position = config.position or "bottom"

  local tabRow = 0
  if position == "bottom" then
    tabRow = vim.o.lines - winHeight - 5
  elseif position == "top" then
    tabRow = 3
  end

  print("TabBar width: " .. winWidth)

  return {
    relative = "editor",
    width     = winWidth,
    height    = 1,
    row       = tabRow,
    col       = 0,
    style     = "minimal",
    border    = "none",
    focusable = false,
  }
end

return M
