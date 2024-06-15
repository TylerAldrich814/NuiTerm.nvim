--> NuiTerm/Config/defaults.lua
--
local Defaults = {}

Defaults.winConfig = function()
  return {
    width    = vim.o.columns,
    height   = 20,
    position = "bottom",
    style    = "minimal",
    border   = "rounded"
  }
end

---@param col   number
---@param row   number
Defaults.tabBarConfig = function(row, col)
  return {
    relative  = "win",
    width     = 2, -- no border padding
    height    = 1,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "none",
    focusable = false,
  }
end

---@param col   number
---@param row   number
---@param width number
Defaults.tabConfig = function(col, row, width)
  return {
    col    = col,
    row    = row,
    width  = 25,
    height = 1,
    nuiWidth = width
  }
end

return Defaults
