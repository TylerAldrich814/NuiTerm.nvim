--> NuiTerm/MainWindow.luaMain
--
local EVENTS = require("NuiTerm.Events.EventDispatcher").EVENTS
-- local TabBar = require("NuiTerm.UI.TabBar.Bar")
local Keymaps = require("NuiTerm.Keymap.Term")
local Utils = require("NuiTerm.utils")
local TermWindow = require("NuiTerm.UI.Term")
local Debug = require("NuiTerm.Debug")
local api = vim.api

local log = Debug.LOG_FN("MainWindow", {
  deactivate = false,
})

---@enum nuiterm.NuiState
local NuiState = {
  Initializing = 0,
  NormalMode   = 1,
  TerminalMode = 2,
  Renaming     = 3,
  Resizing     = 4,
}

---@class MainWindow
local MainWindow = { }

function MainWindow:new(dispatcher, winConfig, shellConfig)
  if not winConfig then
    error("MainWindow:new --> Window Configuration for MainWindow cannot be nil", 2)
  end
  local obj       = setmetatable({
    dispatcher    = dispatcher,
    mainNsid      = api.nvim_create_namespace("TermWin"),
    termNsid      = api.nvim_create_namespace("MainWin"),
    mainWinid     = nil,
    mainWinBufnr  = nil,
    curTermWinid  = nil,
    initialized   = false,
    showing       = false,
    totalTerms    = 0,
    currentTermID = nil,
    winConfig     = winConfig,
    shellConfig   = shellConfig,
    resizeCmdID   = nil,
    stateChanging = false,
    termWindows   = {},
    previousState = nil,
    currentState  = NuiState.Initializing,
  }, { __index = self })
  return obj
end

function MainWindow:PushSubscriptions()
  self.dispatcher:subscribe(EVENTS.show_nuiterm, function(_)
    self:Show()
  end)
  self.dispatcher:subscribe(EVENTS.hide_nuiterm, function(_)
    self:Hide()
  end)
  self.dispatcher:subscribe(EVENTS.update_ui, function(_)
    self:UpdateUI()
  end)
  self.dispatcher:subscribe(EVENTS.new_terminal, function(_)
    self:NewTerm()
  end)
  self.dispatcher:subscribe(EVENTS.delete_nuiterm, function(arg)
    self:DeleteTerm(arg)
  end)
  self.dispatcher:subscribe(EVENTS.next_terminal, function(_)
    self:NextTerm()
  end)
  self.dispatcher:subscribe(EVENTS.prev_terminal, function(_)
    self:PrevTerm()
  end)
  self.dispatcher:subscribe(EVENTS.goto_terminal, function(arg)
    self:ToTerm(arg)
  end)
  self.dispatcher:subscribe(EVENTS.term_resizing, function(args)
    self:OnTermResize(args)
  end)
  self.dispatcher:subscribe(EVENTS.user_resizing, function(data)
    self:Resize(data)
  end)
  self.dispatcher:subscribe(EVENTS.rename_setup, function(_)
    self:RenameStart()
  end)
  self.dispatcher:subscribe(EVENTS.rename_finish, function(args)
    self:RenameFinish(args)
  end)
end

function MainWindow:PushIds()
  self.dispatcher:emit(
    EVENTS.update_current_winid,
    self.termWindows[self.currentTermID].winid
  )
  self.dispatcher:emit(
    EVENTS.update_current_bufnr,
    self.termWindows[self.currentTermID].bufnr
  )
end

function MainWindow:CreateNewTerm()
  local newTermID = self.totalTerms + 1
  local newTerm = TermWindow:Init(newTermID, self.shellConfig)
  self.termWindows[newTermID] = newTerm
  self.totalTerms = #self.termWindows
  self.currentTermID = newTermID
  return newTermID
end

function MainWindow:NewTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  local newTerm = self:CreateNewTerm()
  self:ShowTerminal(newTerm)
  self:PushIds()
  self:UpdateTabBar()
end

function MainWindow:ShowTerminal(id)
  local term = self.termWindows[id]

  if not term then
    local newTermID = self:CreateNewTerm()
    term = self.termWindows[newTermID]
    if not term then
      error("MainWindow:ShowTerminal: Failed to create first terminal")
    end
  end

  local winid = term:Show()
  api.nvim_win_set_hl_ns(winid, self.termNsid)
  api.nvim_set_hl(self.termNsid, "FloatBorder", {
    blend = 90,
    fg = "#FFFFF0"
  })
  self.previousState = self.currentState
  self.currentState = NuiState.TerminalMode
  local currentTerminal = self.termWindows[self.currentTermID]
  if currentTerminal then
    currentTerminal:MoveToLastLine()
  end
  self:PushIds()
  self.curTermWinid = winid

  self:TermMode()
end

function MainWindow:Show()
  local mainWinBufnr = api.nvim_create_buf(false, true)
  vim.bo[mainWinBufnr].modifiable = false
  vim.bo[mainWinBufnr].bufhidden = "hide"
  local mainWinid = api.nvim_open_win(mainWinBufnr, false, self.winConfig)
  vim.wo[mainWinid].winfixbuf = true

  api.nvim_win_set_hl_ns(mainWinid, self.mainNsid)
  api.nvim_set_hl(self.mainNsid, "FloatBorder", {
    blend = 100,
    fg = "#001011"
  })

  self.mainWinBufnr = mainWinBufnr
  self.mainWinid    = mainWinid
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
  self.showing = true
end

function MainWindow:Hide()
  if not self.showing then return end
  if api.nvim_win_is_valid(self.mainWinid) then
    api.nvim_win_close(self.mainWinid, true)
  end
  if api.nvim_buf_is_valid(self.mainWinBufnr) then
    api.nvim_buf_delete(self.mainWinBufnr, { force=true })
  end

  local currentTerm = self.termWindows[self.currentTermID]
  if not currentTerm then
    return
  end
  currentTerm:Hide()
  self.curTermWinid   = nil
  self.showing = false
  -- api.nvim_del_autocmd(self.resizeCmdID)
end

--TODO: when deleting a term window, term_id+1's shell instance is cloned from term_id-1 ...?
function MainWindow:DeleteTerm(term_id)
  if not term_id then term_id = self.currentTermID end
  self.dispatcher:emit(EVENTS.hide_nuiterm, nil)
  if self.totalTerms == 1 then
    self.termWindows   = {}
    self.totalTerms    = 0
    self.currentTermID = nil
    self.initialized   = false
    self.dispatcher:emit(EVENTS.exit_nuiterm, nil)
    return
  end
  self.stateChanging = true

  local terms = self.termWindows
  local left, right = {}, {}

  for i = 1, self.totalTerms do
    if i < term_id then
      table.insert(left, terms[i])
    elseif i > term_id then
      table.insert(right, terms[i])
    end
  end

  self.termWindows = {}
  for _, t in ipairs(left) do
    table.insert(self.termWindows, t)
  end
  for _, t in ipairs(right) do
    table.insert(self.termWindows, t)
  end
  if term_id == self.totalTerms then
    self.currentTermID = self.currentTermID - 1
  end

  self.totalTerms = self.totalTerms - 1
  self:Show()
  self:PushIds()
  self.stateChanging = false
end

function MainWindow:ToTerm(term_id)
  if term_id > self.totalTerms or term_id < 1 then
    return
  end
  self.termWindows[self.currentTermID]:Hide()
  self.currentTermID = term_id
  self:PushIds()
  self:ShowTerminal(term_id)
  self:UpdateTabBar()
end

function MainWindow:NextTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID % self.totalTerms) + 1
  self:PushIds()
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
end

function MainWindow:PrevTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID - 2 + self.totalTerms) % self.totalTerms + 1
  self:PushIds()
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
end

function MainWindow:TermMode()
  self.resize = false
  if not self.curTermWinid or not api.nvim_win_is_valid(self.curTermWinid) then
    return
  end
  api.nvim_win_set_hl_ns(self.curTermWinid, self.termNsid)
  api.nvim_set_hl(self.termNsid, "FloatBorder", {
    blend = 90,
    fg = "#FAAAA0",
  })
  api.nvim_feedkeys(api.nvim_replace_termcodes("i", true, true, true), 'n', true)
end

function MainWindow:NormMode()
  api.nvim_win_set_hl_ns(self.curTermWinid, self.termNsid)
  api.nvim_set_hl(self.termNsid, "FloatBorder", {
    blend = 00,
    fg = "#FFFFF0",
  })
  api.nvim_feedkeys(api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), 'n', true)
end

function MainWindow:GetTermNames()
  local names = {}
  for i = 1, self.totalTerms do
    table.insert(names, self.termWindows[i].name)
  end
  return names
end

function MainWindow:UpdateUI()
  self:Hide()
  self:Show()
end

function MainWindow:UpdateTabBar()
  self.dispatcher:emit(EVENTS.update_tab_bar, {
    tabNames      = self:GetTermNames(),
    currentTermID = self.currentTermID,
    currentWinid  = self.mainWinid,
  })
end

--- TuiTerm Resizing ---
---                  ---
---@param arg number|string
function MainWindow:Resize(arg)
  self.previousState = self.currentState
  self.currentState  = NuiState.Resizing
  self.stateChanging = true
  local num = tonumber(arg)
  if not num then return end
  self.winConfig.height = self.winConfig.height + arg
  self.winConfig.row = vim.o.lines - self.winConfig.height - 4

  for _, term in pairs(self.termWindows) do
    term:UpdateConfig(self.winConfig)
  end
  self:Hide()
  self:Show()
  self.stateChanging = false
  local state        = self.currentState
  self.currentState  = self.previousState
  self.previousState = state
end

---@param args table
function MainWindow:OnTermResize(args)
  vim.defer_fn(function()
    self.previousState = self.currentState
    self.currentState  = NuiState.Resizing
    self:NormMode()
    self:Hide()
    local width = args.width
    local winCol = args.winCol
    self.winConfig.width        = width
    self.winConfig.col          = winCol

    for _, term in pairs(self.termWindows) do
      term:UpdateConfig(self.winConfig)
    end
    self:Show()
    local state        = self.currentState
    self.currentState  = self.previousState
    self.previousState = state
  end, 400)
end

function MainWindow:RenameStart()
  log("Starting Rename Proceedure", "RenameStart")
  self.previousState = self.currentState
  self.currentState  = NuiState.Resizing
  if not self.showing then
    print("NuiTerm is not active")
    return
  end
  Keymaps.RemoveTermKeymaps(self.termWindows[self.currentTermID].bufnr)
  self.dispatcher:emit(EVENTS.rename_start, {
    termWinid    = self.termWindows[self.currentTermID].winid,
    nuiWinid     = api.nvim_get_current_win(),
    nuiWinHeight = self.winConfig.height,
    nuiWinWidth  = self.winConfig.width,
    terminalID   = self.currentTermID,
  })
end

function MainWindow:RenameFinish(newName)
  log("Ending Rename Proceedure", "RenameStart")
  if not newName then
    error("args is nil", 1)
  end
  self.termWindows[self.currentTermID].name = newName
  Keymaps.AddTermKeyMaps(self.termWindows[self.currentTermID].bufnr)
  self:UpdateTabBar()
  self:NormMode()
  local state        = self.currentState
  self.currentState  = self.previousState
  self.previousState = state
end

return MainWindow
