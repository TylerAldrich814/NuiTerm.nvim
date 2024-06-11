--> NuiTerm/TabBar.lua
--

-- local Debug = require("NuiTerm.Debug").Debug
---@class TabBar
local TabBar = {
  ---@type number|nil
  bufnr = nil,
  ---@type table
  config = {}
}
-- TabBar.__index = TabBar

function TabBar:New(config)
  if not config then
    error("TabBar is nil", 2)
  end
  local obj = setmetatable({}, {__index = self})
  obj.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[obj.bufnr].bufhidden = "hide"
  obj.config = config
  return obj
end

function TabBar:Show()
  if not self.config.width then
    error("TabBar.config.width is nil", 2)
  end
  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
end

function TabBar:SetTabs(tabs)
  self.tabs = tabs
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {
    table.concat(tabs, " | ")
  })
end
function TabBar:HighlightActiveTab(index)
  vim.api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
  local line      = 0
  local col_start = 0

  for i, tab in ipairs(self.tabs) do
    local col_end = col_start + #tab
    local group = "TabLine"
    if i == index then group = "TabLineSet" end
    vim.api.nvim_buf_add_highlight(self.bufnr, 0, group, line, col_start, col_end)
    col_start = col_end + 3 -- " | ".len()
  end
end

function TabBar:Hide()
  if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
    -- Debug("Tabbar:Hide() Nothing to hide")
    return
  end
  vim.api.nvim_win_hide(self.winid)
  self.winid = nil
end


return {
  TabBar = TabBar
}
