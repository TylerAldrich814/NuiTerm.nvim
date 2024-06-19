--> NuiTerm/UI/Rename.lua
--
local Defaults = require("NuiTerm.Config.Defaults")
local EVENTS = require("NuiTerm.Events.EventDispatcher").EVENTS
local utils  = require("NuiTerm.utils")
local api = vim.api

local log = require("NuiTerm.Debug").LOG_FN("NuiTermRename", {
  deactivated = false,
})

---@class NuiTermRename
---@field dispatcher   NTEventDispatcher
---@field inputBufnr   number
---@field labelWinOpts RenameLabelConfig
---@field inputWinOpts RenameInputConfig
local NuiTermRename = {}

---@param dispatcher NTEventDispatcher
function NuiTermRename:new(dispatcher)
  log("New NuiTermRename")
  local obj = setmetatable({
    dispatcher   = dispatcher,
    inputBufnr   = nil,
    labelWinOpts = Defaults.RenameLabelConfig(),
    inputWinOpts = Defaults.RenameInputConfig(),
  }, { __index = self })
  return obj
end

---@param callback {onLeave: function, onCancel: function}
function NuiTermRename:OnEnterCallback(callback)
  local autocmd_id = nil
  local function onEnterCmdRecv()
    local newName = api.nvim_buf_get_lines(self.inputBufnr, 0, 1, false)[1]
    if autocmd_id then
      api.nvim_del_autocmd(autocmd_id)
    end
    callback.onLeave()
    self.dispatcher:emit(EVENTS.rename_finish, newName)
  end
  local function onCancelCmd()
    if autocmd_id then
      api.nvim_del_autocmd(autocmd_id)
    end
    callback.onLeave()
    callback.onCancel()
  end
  api.nvim_buf_set_keymap(self.inputBufnr, 'i', '<CR>', '', {
    noremap  = true,
    silent   = true,
    callback = onEnterCmdRecv,
  })
  api.nvim_buf_set_keymap(self.inputBufnr, 'n', '<CR>', '', {
    noremap  = true,
    silent   = true,
    callback = onEnterCmdRecv,
  })
  api.nvim_buf_set_keymap(self.inputBufnr, 'n', '<Esc>', '', {
    noremap  = true,
    silent   = true,
    callback = onCancelCmd,
  })
  autocmd_id = api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
    buffer   = self.inputBufnr,
    callback = onCancelCmd,
    once     = true
  })
end

function NuiTermRename:Activate(config)
  log("Setting up NuiTermRename Windows", "Activate")
  local label = " Rename: "
  local termWinid    = config.termWinid
  local nuiWinid     = config.nuiWinId
  local nuiWinHeight = config.nuiWinHeight
  local nuiWinWidth  = config.nuiWinWidth
  local currentTab   = config.currentTab
  local tabName = string.format("%s", currentTab.name)

  local center = math.floor(nuiWinWidth / 2)
  if center % 2 == 1 then center = center-1 end

  local renamePopupWidth  = self.inputWinOpts.width + #label
  local popupColPosition  = center - math.floor(renamePopupWidth/2)

  self.labelWinOpts.win   = nuiWinid
  self.labelWinOpts.row   = nuiWinHeight
  self.labelWinOpts.col   = popupColPosition-#label

  self.inputWinOpts.win   = nuiWinid
  self.inputWinOpts.row   = nuiWinHeight
  self.inputWinOpts.col   = popupColPosition

  local labelBufnr = api.nvim_create_buf(false, true)
  local inputBufnr = api.nvim_create_buf(false, true)
  local labelWin   = api.nvim_open_win(labelBufnr, false, self.labelWinOpts)
  local inputWin   = api.nvim_open_win(inputBufnr, true,  self.inputWinOpts)
  self.inputBufnr  = inputBufnr

  api.nvim_buf_set_lines(labelBufnr, 0, -1, true,  { label })
  api.nvim_buf_set_lines(inputBufnr, 0, -1, false, { tabName })

  vim.bo[labelBufnr].modifiable = false
  vim.bo[labelBufnr].bufhidden  = "wipe"
  vim.bo[inputBufnr].bufhidden  = "wipe"

  api.nvim_win_set_cursor(inputWin, { 1, #tabName+1 })
  api.nvim_feedkeys('a', 'i', true)

  local removeWinBufs = function()
    if api.nvim_win_is_valid(labelWin) then
      api.nvim_win_close(labelWin, true)
    end
    if api.nvim_win_is_valid(inputWin) then
      api.nvim_win_close(inputWin, true)
    end
    if api.nvim_buf_is_valid(labelBufnr) then
      api.nvim_buf_delete(labelBufnr, { force = false } )
    end
    if api.nvim_buf_is_valid(inputBufnr) then
      api.nvim_buf_delete(inputBufnr, { force = true})
    end
  end
  self:OnEnterCallback({
    onLeave   = function()
      removeWinBufs()
      api.nvim_win_set_cursor(termWinid, { 4,4 })
      self:Deactivate()
    end,
    onCancel = function()
      self.dispatcher:emit(EVENTS.rename_finish, currentTab.name)
    end
  })
end

function NuiTermRename:Deactivate()
  self = NuiTermRename:new(self.dispatcher)
end

return NuiTermRename
