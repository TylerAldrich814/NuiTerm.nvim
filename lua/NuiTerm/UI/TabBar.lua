--> NuiTerm/TabBar.lua
--
local Debug = require("NuiTerm.Debug")
local Utils = require("NuiTerm.utils")
local fn, api, map = vim.fn, vim.api, vim.keymap.set
local AUGROUP = api.nvim_create_augroup("NuiTermTabHover", { clear=true })

local log = Debug.LOG_FN("TabBar", {
  deactivate = true,
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
  height,
  mainWinId
)
  local obj = setmetatable({}, {__index = self})
  obj.name = name
  obj.bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[obj.bufnr].buftype = "nofile"
  vim.bo[obj.bufnr].bufhidden = "hide"
  obj.config = {
    relative  = "win",
    win       = mainWinId,
    style     = "minimal",
    border    = "none",
    zindex    = 100,
    focusable = false,
    col       = col,
    -- row       = row,
    row = 0,
    width     = width,
    height    = height,
  }
  Utils.PreventFileOpenInTerm(obj.bufnr)
  return obj
end

---@param onClick function
function Tab:Display(onClick)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    log("self.bufnr not a valid bufnr: "..self.bufnr)
  end

  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  vim.wo.winfixbuf = true -- Disables Files from loading in Term window!

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
-------------------------------------------------------
--TODO: Figure out how to gracfully close the TabBar when you quit NuiTerm via ':q'&':q!'..

---@class TabBar
---@field winid      number|nil
---@field bufnr      number|nil
---@field tabs       Tab[]
---@field config     table
---@field tabConfig  table
---@field seperator  string
---@field onClick    function
local TabBar = {
  winid     = nil,
  bufnr     = nil,
  tabs      = {},
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

function TabBar:SetTabs(termTabs, focusedIdx, mainWinId)
  self:Hide()
  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  local row    = self.tabConfig.row
  local col    = 0-- self.tabConfig.col
  local width  = self.tabConfig.width
  local height = self.tabConfig.height

  log("Col: " .. self.tabConfig.col .. "Row: " .. self.tabConfig.row)
  for _, tabName in ipairs(termTabs) do
    local tab
    tab = Tab:New(tabName, col, row, width, height, mainWinId)
    table.insert(self.tabs, tab)
    col = col + width + 1
  end

  for _, tab in ipairs(self.tabs) do
    tab:Display( self.onClick )
  end

  for i, tab in ipairs(self.tabs) do
    local group = "TabLine"
    if i == focusedIdx then group = "TabLineSel" end
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

local delay    = 500
local timer    = nil
local prev_pos = nil

function TabBar:Hide()
  if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
    log("self.winid is not valid")
    return
  end
  for _, tab in ipairs(self.tabs) do
    tab:Hide()
  end
  vim.api.nvim_win_hide(self.winid)
  self.winid = nil
  self.tabs = {}
end

local function onHover(position)
  if vim.o.showtabline == 0 then return end
  if position.screenrow == 1 then
    api.nvim_exec_autocmds("User", {
      pattern = "TabBarHoverOver",
      data = { cursor_pos = position.screencol }
    })
  elseif prev_pos and prev_pos.screenrow == 1 and position.screenrow ~= 1 then
    api.nvim_exec_autocmds("User", {
      pattern = "TabBarHoverOut",
      data = {}
    })
  end
end


function TabBar:setupOnHover()
  map({"", "i"}, "<MouseMove>", function()
    if timer then timer:close() end
    timer = vim.defer_fn(function()
      timer = nil
      local ok, pos = pcall(fn.getmousepos)
      if not ok then return end
      onHover(pos)
    end, delay)
    return "<MouseMove>"
  end, { expr = true })

  api.nvim_create_autocmd("VimLeavePre", {
    group = AUGROUP,
    callback = function()
      if timer then
        timer:close()
        timer = nil
      end
    end
  })
end

--- If 'abs' is true, then we update our row positions relativly with our original values.
--- Otherwise, we update our row positions absolutely.
---@param row string|number
---@param abs boolean
function TabBar:UpdateRow(row, abs)
  if abs then
    self.config.row    = row
    self.tabConfig.row = row
  else
    self.config.row    = self.config.row - row
    self.tabConfig.row = self.tabConfig.row - row
  end
end

--- If 'abs' is true, then we update our col positions relativly with our original values.
--- Otherwise, we update our col positions absolutely.
---@param col string|number
---@param abs boolean
function TabBar:UpdateCol(col, abs)
  if abs then
    self.config.col    = col
    self.tabConfig.col = col
  else
    self.config.col    = self.config.col - col
    self.tabConfig.col = self.tabConfig.col - col
  end
end

function TabBar:UpdateWidth(width)
  self.config.width = width
end

return {
  TabBar = TabBar
}
