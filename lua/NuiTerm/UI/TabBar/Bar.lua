--> NuiTerm/TabBar/Bar.lua
--
local EVENTS = require("NuiTerm.Events.EventDispatcher").EVENTS
local Tab   = require("NuiTerm.UI.TabBar.Tab")
local fn, api, map = vim.fn, vim.api, vim.keymap.set
local AUGROUP = api.nvim_create_augroup("NuiTermTabHover", { clear=true })
local NuiTermRename = require("NuiTerm.UI.Rename")

local log = require("NuiTerm.Debug").LOG_FN("TabBar", {
  deactivate = false,
})

vim.api.nvim_set_hl(0, 'TabLine', { fg = '#ffffff', bg = '#000000' }) -- Customize colors as needed
vim.api.nvim_set_hl(0, 'TabLineSel', { fg = '#000000', bg = '#ffffff' }) -- Customize colors as needed

------------------------ TabBar ------------------------ 
-------------------------------------------------------
--TODO: Figure out how to gracfully close the TabBar when you quit NuiTerm via ':q'&':q!'..

---@class TabBar
local TabBar = { }

---@param dispatcher NTEventDispatcher
---@param barConfig  table
---@param tabConfig  table
function TabBar:new(dispatcher, barConfig, tabConfig)
  if not barConfig then
    error("BarConfig is nil", 2)
  end
  if not tabConfig then
    error("TabConfig is nil", 2)
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].bufhidden = "hide"
  local obj = setmetatable({
    dispatcher = dispatcher,
    nuiTermRename = NuiTermRename:new(dispatcher),
    bufnr     = bufnr,
    winid     = nil,
    tabs      = {},
    config    = barConfig,
    tabConfig = tabConfig,
    seperator = "▎",
  }, {__index = self})
  return obj
end

function TabBar:PushSubscriptions()
  self.dispatcher:subscribe(EVENTS.update_tab_bar, function(args)
    self:SetTabs(args)
  end)
  self.dispatcher:subscribe(EVENTS.hide_nuiterm, function(_)
    self:Hide()
  end)
  self.dispatcher:subscribe(EVENTS.rename_start, function(args)
    self:RenameStart(args)
  end)
  self.dispatcher:subscribe(EVENTS.term_resizing, function(args)
    self:OnTermResize(args)
  end)
end

function TabBar:SetTabs(args)
  if not args then
    error("Args is nil")
  end
  local tabNames      = args.tabNames
  local currentTermID = args.currentTermID
  local currentWinid  = args.currentWinid
  if not tabNames then
    error("tabNames is nil")
  end
  if not currentTermID then
    error("currentTermID is nil")
  end
  if not currentWinid then
    error("currentWinid is nil")
  end
  self:Hide()
  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  local col    = 1
  local width  = self.tabConfig.width
  local height = self.tabConfig.height

  for i, tabName in ipairs(tabNames) do
    local tab
    tab = Tab:new(i, tabName, col, width, height, currentWinid)
    table.insert(self.tabs, tab)
    col = col + width
  end

  for _, tab in ipairs(self.tabs) do
    tab:Display( self.onClick )
  end

  for i, tab in ipairs(self.tabs) do
    local group = "TabLine"
    if i == currentTermID then group = "TabLineSel" end
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

---@param args table
function TabBar:OnTermResize(args)
  local tabCol = args.tabCol
  local width  = args.width
  self:UpdateCol(tabCol, true)
  self:UpdateWidth(width)
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

---@ RENAMING Functions <---

---@param renameBufnr number
---@param callback    function
---@param cleanup     function
local function RenameOnEnterCallback(renameBufnr, callback, cleanup)
  local function onLeave()
    cleanup()
  end
  local function onHitEnter()
    local newName = api.nvim_buf_get_lines(renameBufnr, 0, 1, false)[1]
    onLeave()
    callback(newName)
  end
  api.nvim_buf_set_keymap(renameBufnr, 'i', '<CR>', '', {
    noremap  = true,
    silent   = true,
    callback = onHitEnter
  })
  api.nvim_buf_set_keymap(renameBufnr, 'n', '<CR>', '', {
    noremap  = true,
    silent   = true,
    callback = onHitEnter
  })
  api.nvim_buf_set_keymap(renameBufnr, 'n', '<Esc>', '', {
    noremap  = true,
    silent   = true,
    callback = onLeave,
  })

  api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
    buffer = renameBufnr,
    callback = function()
      onLeave()
    end,
    once = true
  })
end

function TabBar:RenameStart(args)
  log("Starting Rename Proceedure", "RenameStart")
  if not args or type(args) ~= "table" then
    error("Args in either nil or not a table", 1)
  elseif not args.termWinid or type(args.termWinid) ~= "number" then
    error("args.termWinid in either nil or not a table", 1)
  elseif not args.nuiWinid or type(args.nuiWinid) ~= "number" then
    error("args.nuiWinid in either nil or not a table", 1)
  elseif not args.nuiWinHeight or type(args.nuiWinHeight) ~= "number" then
    error("args.nuiWinHeight in either nil or not a table", 1)
  elseif not args.nuiWinWidth or type(args.nuiWinWidth) ~= "number" then
    error("args.nuiWinWidth in either nil or not a table", 1)
  elseif not args.terminalID or type(args.terminalID) ~= "number" then
    error("args.terminalID in either nil or not a table", 1)
  elseif not self.tabs[args.terminalID] then
    error("args.terminalID is out of bounds. No Tab matching this index", 1)
  end
  log("Calling nuiTermRename:Activate", "RenameStart")
  self.nuiTermRename:Activate({
    termWinid    = args.termWinid,
    nuiWinid     = args.nuiWinid,
    nuiWinHeight = args.nuiWinHeight,
    nuiWinWidth  = args.nuiWinWidth,
    tabWidth     = self.tabConfig.width+10,
    currentTab   = self.tabs[args.terminalID]
  })
end

---@param mainWinId      number
---@param mainWinHeight  number
---@param termID         number
---@param renameCallback function  
function TabBar:Rename(mainWinId, mainWinHeight, termID, renameCallback)
  local curTab     = self.tabs[termID]
  local renameText = " Rename: "
  local currentWin = api.nvim_get_current_win()

  local tabWidth   = self.tabConfig.width+10
  local tabHeight  = 1
  local termWidth  = self.tabConfig.nuiWidth

  local center     = math.floor(termWidth/2)
  if center % 2 == 1 then center = center-1 end
  local renamePopupWidth = tabWidth+#renameText

  local renameSignOpts = {
    relative = "win",
    win      = mainWinId,
    width    = 10,
    height   = tabHeight,
    style    ="minimal",
    border   = "rounded",
    row      = mainWinHeight,
    col      = center-math.floor(renamePopupWidth/2)-#renameText
  }
  local renameWindowOpts = {
    relative = "win",
    win      = mainWinId,
    width    = tabWidth+10,
    height   = tabHeight,
    style    = "minimal",
    border   = "rounded",
    row      = mainWinHeight,
    col      = center-math.floor(renamePopupWidth/2)
  }
  local renameSignBuf    = api.nvim_create_buf(false, true)
  local renameWindowBuf  = api.nvim_create_buf(false, true)

  local renameSign = api.nvim_open_win(renameSignBuf, false, renameSignOpts)
  local renameWindow = api.nvim_open_win(renameWindowBuf, true, renameWindowOpts)

  api.nvim_buf_set_lines(renameWindowBuf, 0, -1, false, {curTab.name})
  api.nvim_buf_set_lines(renameSignBuf, 0, -1, true, {renameText})

  vim.bo[renameSignBuf].modifiable  = false
  vim.bo[renameWindowBuf].bufhidden = "wipe"
  vim.bo[renameSignBuf].bufhidden   = "wipe"

  api.nvim_win_set_cursor(renameWindow,{ 1, #curTab.name+1 })
  api.nvim_feedkeys('a', 'i', true)

  RenameOnEnterCallback(renameWindowBuf,
    function(newName)
      renameCallback(newName)
    end,
    function()
      if api.nvim_win_is_valid(renameSign) then
        api.nvim_win_close(renameSign, true)
      end
      if api.nvim_win_is_valid(renameWindow) then
        api.nvim_win_close(renameWindow, true)
      end
      if api.nvim_buf_is_valid(renameSignBuf) then
        api.nvim_buf_delete(renameSignBuf, { force = false } )
      end
      if api.nvim_buf_is_valid(renameWindowBuf) then
        api.nvim_buf_delete(renameWindowBuf, { force = true})
      end
      api.nvim_win_set_cursor(currentWin, {4, 3})
    end
  )
end


return TabBar
