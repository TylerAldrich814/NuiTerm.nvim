--> NuiTerm/TabBar/Bar.lua
--
local Tab   = require("NuiTerm.UI.TabBar.Tab")
local fn, api, map = vim.fn, vim.api, vim.keymap.set
local AUGROUP = api.nvim_create_augroup("NuiTermTabHover", { clear=true })

local log = require("NuiTerm.Debug").LOG_FN("TabBar", {
  deactivate = false,
})

vim.api.nvim_set_hl(0, 'TabLine', { fg = '#ffffff', bg = '#000000' }) -- Customize colors as needed
vim.api.nvim_set_hl(0, 'TabLineSel', { fg = '#000000', bg = '#ffffff' }) -- Customize colors as needed

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

---@param termTabs   string[]
---@param focusedIdx number
---@param mainWinId  number
function TabBar:SetTabs(termTabs, focusedIdx, mainWinId)
  self:Hide()
  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  local col    = 1
  local width  = self.tabConfig.width
  local height = self.tabConfig.height

  for i, tabName in ipairs(termTabs) do
    local tab
    tab = Tab:New(i, tabName, col, width, height, mainWinId)
    table.insert(self.tabs, tab)
    col = col + width
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

function TabBar:Rename(termID)
  log("Renaming", "Rename")
  self.tabs[termID]:Rename()
end

return TabBar
