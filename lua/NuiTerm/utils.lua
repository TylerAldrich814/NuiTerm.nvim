--> NuiTerm/utils.lua
--

local M = {}

M.GetTermSize = function()
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

return M
