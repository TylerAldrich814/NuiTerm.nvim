--> NuiTerm/MainWindow.lua
--
local TabBar = require("NuiTerm.UI.TabBar").TabBar

local Utils = require("NuiTerm.utils")
-- local TermCreate = require("NuiTerm.Term").TermCreate
local TermWindow = require("NuiTerm.Term").TermWindow
-- local Term = require("NuiTerm.Term")
local Debug = require("NuiTerm.Debug")

local function log(msg, src)
  local source = "MainWindow"
  if src then
    source = source .. ":" .. src
  end
  Debug.push_message(source, msg)
end

---@class MainWindow
---@field nsid          integer|nil
---@field winid         integer|nil
---@field initialized   boolean
---@field showing       boolean
---@field totalTerms    number
---@field currentTermID number|nil
---@field termWindows   TermWindow[]
---@field winConfig     table
---@field tabBar        TabBar
local MainWindow = {
  nsid           = nil,
  winid          = nil,
  initialized    = false,
  showing        = false,
  totalTerms     = 0,
  currentTermID  = nil,
  termWindows    = {},
  winConfig      = {},
  tabBar         = TabBar
}

function MainWindow:New(winConfig, tabBarConfig)
  if not winConfig then
    error("MainWindow:new --> Window Configuration for MainWindow cannot be nil", 2)
  end
  if not tabBarConfig then
    error("MainWindow:new --> TabBar Configuration for MainWindow cannot be nil", 2)
  end
  local obj = setmetatable({}, { __index = self })
  obj.nsid = vim.api.nvim_create_namespace("NuiTerm")
  obj.winConfig = winConfig
  obj.tabBar    = TabBar:New(tabBarConfig)
  return obj
end

function MainWindow:CreateNewTerm()
  log("Createing New Terminal Window", "CreateNewTerm")
  local newTermID = self.totalTerms + 1
  local newTerm = TermWindow:Init(newTermID, self.winConfig)
  self.termWindows[newTermID] = newTerm
  self.totalTerms = #self.termWindows
  self.currentTermID = newTermID
  return newTermID
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

  local winid = term:Show(function() self:Hide() end)
  vim.api.nvim_win_set_hl_ns(winid, self.nsid)
  vim.api.nvim_set_hl(self.nsid, "FLoatBorder", {
    blend = 90,
    fg = "#FFFFF0"
  })
  self.winid = winid
end

function MainWindow:Show()
  log("Showing", "Show")
  self:ShowTerminal(self.currentTermID)
  self.tabBar:Show()
  self:UpdateTabBar()
  self:TermMode()
  self.showing = true
end

function MainWindow:Hide()
  log("Hiding NuiTerm", "Hide")
  if not self.showing then return end

  local currentTerm = self.termWindows[self.currentTermID]
  if not currentTerm then
    log("Terminal to Hide", "Hide")
    return
  end
  currentTerm:Hide()
  self.tabBar:Hide()
  self.winid   = nil
  self.showing = false
end

function MainWindow:Toggle()
  if not self.showing then
    self:Show()
  else
    self:Hide()
  end
end

function MainWindow:NewTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  local newTerm = self:CreateNewTerm()
  self:ShowTerminal(newTerm)
  self:UpdateTabBar()
end

function MainWindow:DeleteTerm(term_id)
  if not term_id then
    term_id = self.currentTermID
  end
  if self.termWindows[term_id] then
    self.termWindows[term_id]:Hide()
    self.termWindows[term_id] = nil
    if term_id < self.totalTerms then
      -- Go through id+1 terminal instances, lower their term_id's by 1
      for i = term_id+1, self.totalTerms do
        ---@class TermWindow
        local term = self.termWindows[i]
        if term then
          term.termid = term.termid-1
        end
      end
    end
    self:UpdateTabBar()
  end
end

function MainWindow:ToTerm(term_id)
  if term_id > self.totalTerms or term_id < 0 then
    return
  end
  self.termWindows[self.currentTermID]:Hide()
  self.currentTermID = term_id
  self:ShowTerminal(term_id)
  self:UpdateTabBar()
end

function MainWindow:DebugBufs()
  for _, t in pairs(self.termWindows) do
    log("TermID: " .. t.termid .. " - Bufnr: " .. t.bufnr)
  end
end

function MainWindow:NextTerm()
  self:DebugBufs()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID % self.totalTerms) + 1
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
  log("CurrentTermID: "..self.currentTermID, "NextTerm")
end

function MainWindow:PrevTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID - 1 + self.totalTerms) % self.totalTerms + 1
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
  log("CurrentTermID: "..self.currentTermID, "PrevTerm")
end

function MainWindow:TermMode()
  if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
    log("self.winid is NIL", "TermMode")
    return
  end
  vim.api.nvim_win_set_hl_ns(self.winid, self.nsid)
  vim.api.nvim_set_hl(self.nsid, "FloatBorder", {
    blend = 90,
    fg="#FAAAA0",
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, true, true), 'n', true)
end

function MainWindow:NormMode()
  local ns = vim.api.nvim_get_namespaces()["NuiTerm"]

  vim.api.nvim_win_set_hl_ns(self.winid, self.nsid)
  vim.api.nvim_set_hl(self.nsid, "FloatBorder", {
    blend = 00,
    fg="#FFFFF0",
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), 'n', true)
end

function MainWindow:GetTabNames()
  local names = {}
  -- for i = 1, self.totalTerms do
  --   table.insert(names, "Term " .. i)
  -- end
  for _, i in pairs(self.termWindows) do
    if not i.termid then
      table.insert(names, "NO TERM")
    else
      table.insert(names, "Term " .. i.termid)
    end
  end
  return names
end
function MainWindow:UpdateTabBar()
  self.tabBar:SetTabs(self:GetTabNames())
  self.tabBar:HighlightActiveTab(self.currentTermID+1)
end

return {
  MainWindow = MainWindow
}