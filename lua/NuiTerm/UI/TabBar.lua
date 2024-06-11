--> NuiTerm/TabBar.lua
--
local Debug = require("NuiTerm.Debug")

local log = Debug.LOG_FN("TabBar", {
  deactivate = false,
})

vim.api.nvim_set_hl(0, 'TabLine', { fg = '#ffffff', bg = '#000000' }) -- Customize colors as needed
vim.api.nvim_set_hl(0, 'TabLineSel', { fg = '#000000', bg = '#ffffff' }) -- Customize colors as needed

------------------------- Tab --------------------------
--------------------------------------------------------
---@class Tab
---@field bufnr  number|nil
---@field winid  number|nil
---@field coord  table
---@field name   string
---@field config table
local Tab = {
  bufnr  = nil,
  winid  = nil,
  coord  = {},
  name   = "",
  config = {},
}

---@param name     string
---@param col      number
---@param row      number
---@param width    number
---@param height   number
function Tab:New(
  name,
  col,
  row,
  width,
  height
)
  local obj = setmetatable({}, {__index = self})
  obj.name = name
  obj.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[obj.bufnr].bufhidden = "hide"
  obj.config = {
    relative  = "editor",
    style     = "minimal",
    border    = "none",
    zindex    = 100,
    focusable = false,
    col       = col,
    row       = row,
    width     = width,
    height    = height,
  }
  return obj
end

---@param onClick function
function Tab:Display(onClick)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    log("self.bufnr not a valid bufnr: "..self.bufnr)
  end

  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)

  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { self.name })
  -- vim.api.nvim_buf_add_highlight(self.bufnr, 0, group, 0, tabStart, tabEnd)

  -- RightMouse kepmapping
  vim.api.nvim_buf_set_keymap(self.bufnr, 'n', '<RightMouse>', '', {
    callback = function()
      log("Clicked on \"" .. self.name .. "\"")
      onClick()
    end,
    noremap = true,
    silent  = true,
  })

  log("Display Tab: Bufnr: ".. self.bufnr .. " Winid: "..self.winid)
end
function Tab:Highlight(group)
  vim.api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
  vim.api.nvim_buf_add_highlight(self.bufnr, 0, group, 0, 0, -1)
end

function Tab:Hide()
  log("Hiding Tab Bufnr: ".. self.bufnr .. " Winid: " .. self.winid)
  vim.api.nvim_win_hide(self.winid)
  self.winid = nil
end

------------------------ TabBar ------------------------ 
--------------------------------------------------------

---@class TabBar
---@field t Tab[]
---@field winid      number|nil
---@field bufnr      number|nil
---@field tabs       number[]
---@field tabWindows number[]
---@field tabCoords  table
---@field config     table
---@field tabConfig  table
---@field seperator  string
---@field onClick    function
local TabBar = {
  winid     = nil,
  bufnr     = nil,
  t  = {},
  tabs      = {},
  tabWindows = {},
  tabCoords = {},
  config    = {},
  tabConfig = {},
  seperator = "▎",
}

---@param config  table
---@param onClick function
function TabBar:New(config, onClick)
  if not config then
    error("TabBarConfig is nil", 2)
  end
  local obj = setmetatable({}, {__index = self})
  obj.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[obj.bufnr].bufhidden = "hide"
  obj.config    = config.MainBar
  obj.tabConfig = config.Tab
  obj.onClick   = onClick
  return obj
end

function TabBar:SetTabs(termTabs, focusedIdx)
  self:Hide()
  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  local row    = self.tabConfig.row
  local col    = self.tabConfig.col
  local width  = self.tabConfig.width
  local height = self.tabConfig.height

  for _, tabName in ipairs(termTabs) do
    table.insert(self.t, Tab:New(
      tabName,
      col,
      row,
      width,
      height
    ))
    col = col + width + 1
  end

  for i, tab in ipairs(self.t) do
    tab:Display( self.onClick )
  end

  for i, tab in ipairs(self.t) do
    local group = "TabLine"
    if i == focusedIdx then group = "TabLineSel" end
    log(string.format("idx: %d -- Tab %d -- group=%s",focusedIdx, i, group))

    tab:Highlight(group)
  end

  vim.api.nvim_buf_set_keymap(
    self.bufnr,
    'n',
    '<Esc>',
    [[<cmd>lua require('NuiTerm').MainWindow.tabBar:Hide()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )
end


function TabBar:HighlightActiveTab(index)
  vim.api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
  local line = 0
  local col_start = 0

  for i, tab in ipairs(self.tabs) do
    local col_end = col_start + #tab
    local group = "TabLine"
    if i == index then group = "TabLineSel" end
    log(string.format("Tab %d: col_start=%d, col_end=%d, group=%s", i, col_start, col_end, group), "HighlightActiveTab")

    for _, buf in pairs(self.tabs) do
      vim.api.nvim_buf_add_highlight(buf.bufnr, 0, group, line, col_start, col_end)
    end
    col_start = col_end + #self.seperator --3 -- " | ".len()
  end
end

function TabBar:Hide()
  if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
    log("self.winid is not valid")
    return
  end
  for _, tab in ipairs(self.t) do
    tab:Hide()
  end
  vim.api.nvim_win_hide(self.winid)
  self.winid = nil
  self.t = {}
end

return {
  TabBar = TabBar
}
