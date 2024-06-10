--> NuiTerm/MainWindow.lua
--
local Setup = require("NuiTerm.setup")
local Utils = require("NuiTerm.utils")
local TermWindow = require("NuiTerm/Term").TermWindow
local Debug = require("NuiTerm.Debug").Debug

local NSID = Setup.NSID
local GetTermSize = Utils.GetTermSize

local MainWindow = {
  winid       = nil,
  initialized = false,
  showing     = false,
  termWindows = {},
  totalTerms  = 0,
  currentTerm = 0
}
function MainWindow:New()
  return self
end

function MainWindow:CreateNewTerm()
  local width, height = GetTermSize()
  local winConfig = {
    relative = "editor",
    width = width,
    height = 20,
    row = height,
    col = 0,
    style = "minimal",
    border = "rounded"
  }
  local newTerm = TermWindow:Init( self.totalTerms, winConfig )

  if not newTerm then
    Debug("NewTerm Failed to Initialize??")
    return
  end
  self.termWindows[self.totalTerms] = newTerm
  self.totalTerms = self.totalTerms+1
end

function MainWindow:Show()
  local currentTerm = self.termWindows[self.currentTerm]
  if not currentTerm then
    self:CreateNewTerm()
    currentTerm = self.termWindows[self.currentTerm]
  end


  local winid = currentTerm:Show(function() self:Hide() end)
  self.winid = winid
  vim.api.nvim_win_set_hl_ns(winid, NSID)
  vim.api.nvim_set_hl(NSID, "FloatBorder", {
    blend = 90,
    fg="#FFFFF0",
  })

  self.showing = true
end

function MainWindow:Hide()
  local currentTerm = self.termWindows[self.currentTerm]
  if not currentTerm then
    Debug("MainWindow:Hide(): No Terminal to Hide")
    return
  end
  currentTerm:Hide()
  self.winid = nil
  self.showing = false
end

function MainWindow:Toggle()
  if not self.showing then
    Debug("Calling Show")
    self:Show()
  else
    Debug("Calling Hide")
    self:Hide()
  end
end


function MainWindow:TermMode()
  Debug("TermMode: NSID: " .. NSID)
  local ns = vim.api.nvim_get_namespaces()["NuiTerm"]
  Debug("NS: " .. ns)

  vim.api.nvim_win_set_hl_ns(self.winid, NSID)
  vim.api.nvim_set_hl(NSID, "FloatBorder", {
    blend = 90,
    fg="#FAAAA0",
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("i", true, true, true), 'n', true)
end
function MainWindow:NormMode()
  Debug("NormMode: NSID: " .. NSID)
  local ns = vim.api.nvim_get_namespaces()["NuiTerm"]
  Debug("NS: " .. ns)

  vim.api.nvim_win_set_hl_ns(self.winid, NSID)
  vim.api.nvim_set_hl(NSID, "FloatBorder", {
    blend = 00,
    fg="#FFFFF0",
  })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, true, true), 'n', true)
end

return {
  MainWindow = MainWindow
}

