--> NuiTerm/MainWindow.lua
--
local TabBar = require("NuiTerm.UI.TabBar").TabBar

local Utils = require("NuiTerm.utils")
-- local TermCreate = require("NuiTerm.Term").TermCreate
local TermWindow = require("NuiTerm.Term").TermWindow
-- local Term = require("NuiTerm.Term")
local Debug = require("NuiTerm.Debug")

local log = Debug.LOG_FN("MainWindow", {
  deactivate = false,
})

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
---@field resizeCmdID   number|nil
local MainWindow = {
  nsid           = nil,
  winid          = nil,
  initialized    = false,
  showing        = false,
  totalTerms     = 0,
  currentTermID  = nil,
  termWindows    = {},
  winConfig      = {},
  tabBar         = TabBar,
  resizeCmdID    = nil,
  resizing       = false,
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
  obj.tabBar    = TabBar:New(
    tabBarConfig,
    function(idx)
      self:ShowTerminal(idx)
    end
  )
  return obj
end

function MainWindow:CreateNewTerm()
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
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
  if not self.resizing then
    self:TermMode()
  end
  self.showing = true
  self:OnResize()
  self:CtrlMode()
end

function MainWindow:CtrlMode()

end

function MainWindow:Hide()
  if not self.showing then return end

  local currentTerm = self.termWindows[self.currentTermID]
  if not currentTerm then
    return
  end
  currentTerm:Hide()
  self.tabBar:Hide()
  self.winid   = nil
  self.showing = false

  vim.api.nvim_del_autocmd(self.resizeCmdID)
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

--TODO: when deleting a term window, term_id+1's shell instance is cloned from term_id-1 ...?
function MainWindow:DeleteTerm(term_id)
  if not term_id then
    term_id = self.currentTermID
  end

  --- Check within bounds of valid terms
  if term_id < 1 or term_id > self.totalTerms then
    return
  end

  self:Hide()
  table.remove(self.termWindows, term_id)
  -- self.termWindows[term_id] = nil
  -- self:Hide()
  log("Deleted TermID: " .. term_id)
  for i = term_id+1, self.totalTerms do
    -- log(" < Term ID: " .. self.termWindows[i].termid)
    self.termWindows[i] = self.termWindows[i-1]
    -- log(".. is now TermID: " .. self.termWindows[i].termid)
  end
  self.totalTerms = self.totalTerms-1

  log("New Term IDs")
  for _, term in ipairs(self.termWindows) do
    log("Name: "..term.name.. " ID: " .. term.termid)
  end

  --> Update Display
  self:Show()
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

function MainWindow:NextTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID % self.totalTerms) + 1
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
end

function MainWindow:PrevTerm()
  if self.currentTermID then
    self.termWindows[self.currentTermID]:Hide()
  end
  self.currentTermID = (self.currentTermID - 2 + self.totalTerms) % self.totalTerms + 1
  self:ShowTerminal(self.currentTermID)
  self:UpdateTabBar()
end


function MainWindow:TermMode()
  self.resize = false
  if not self.winid or not vim.api.nvim_win_is_valid(self.winid) then
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
  vim.api.nvim_win_set_hl_ns(self.winid, self.nsid)
  vim.api.nvim_set_hl(self.nsid, "FloatBorder", {
    blend = 00,
    fg="#FFFFF0",
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), 'n', true)
end

function MainWindow:GetTabNames()
  local names = {}
  --TODO: Dynamic Tab sizing with padding. After adding Tab Naming Functionality
  for i = 1, self.totalTerms do
    table.insert(names, "    Terminal " .. i .. "    ")
  end
  return names
end

function MainWindow:UpdateTabBar()
  self.tabBar:SetTabs(self:GetTabNames(), self.currentTermID)
end

--- TuiTerm Resizing ---
---                  ---
---@param arg number|string
function MainWindow:Resize(arg)
  self.resizing = true
  local num = tonumber(arg)
  if not num then
    log("Arg passed is not a number: " .. arg, "Resize")
    return
  else
    log("TONumber: " .. num)
  end
  self.winConfig.height = self.winConfig.height + arg
  self.winConfig.row = vim.o.lines - self.winConfig.height - 4

  for _, term in pairs(self.termWindows) do
    term:UpdateConfig(self.winConfig)
  end
  self:Hide()
  self.tabBar:UpdatePos(arg)
  self:Show()
end

function MainWindow:OnResize()
  self.resizeCmdID = vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      vim.defer_fn(function()
        self:NormMode()
        local width, _ = Utils.GetTermSize()
        self.winConfig.width = width
        self.winConfig.height = 20

        for _, term in pairs(self.termWindows) do
          term:UpdateConfig(self.winConfig)
        end
        self:Hide()
        self:Show()
      end, 400)
    end
  })
end

return {
  MainWindow = MainWindow
}
