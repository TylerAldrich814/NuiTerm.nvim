--> NuiTerm/Config/utils.lua
--
local WidthPCT = require("NuiTerm.Utils").WidthPCT
local Utils = {}

---@param winConfig table
Utils.NuiTermWindowConfig = function(winConfig)
  if not winConfig then
    error("CONFIG IS NIL", 2)
  end

  local position = winConfig.position or "bottom"
  local width, col, _ = WidthPCT(winConfig.width or vim.o.columns)
  local row = 0

  if position == "bottom" then
    row = vim.o.lines - winConfig.height - 4
  elseif position == "top" then
    row = 4
  else
    error("- NuiTerm: setup.position --> Found an unknown value - \"" .. position .. "\"")
  end

  return {
    relative = "editor",
    width    = width,
    height   = winConfig.height,
    style    = winConfig.style,
    border   = winConfig.border,
    row      = row,
    col      = col
  }
end

Utils.NuitermTabBarConfig = function(tabConfig)
  local width, col, _ = WidthPCT(tabConfig.width or vim.o.columns)

  local height = tabConfig.height or M.WinHeight
  local position  = tabConfig.position or "bottom"

  local row  = 0
  if position == "bottom" then
    row = vim.o.lines - height - 5
  elseif position == "top" then
    row = 3
  end

  return {
    MainBar = {
      relative  = "win",
      width     = 2, -- no border padding
      height    = 1,
      row       = row,
      col       = col,
      style     = "minimal",
      border    = "none",
      focusable = false,
    },
    Tab = {
      col    = col,
      row    = row,
      width  = 25,
      height = 1,
      nuiWidth = width,
    },
  }
end

return Utils
