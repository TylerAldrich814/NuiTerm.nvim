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

---@param callback {onNewName: function, onLeave: function}
function NuiTermRename:OnEnterCallback(callback)
  local autocmd_id = nil
  local function onLeaveCmd()
    api.nvim_del_autocmd(autocmd_id)
    callback.onLeave()
  end
  local function onEnterCmdRecv()
    local newName = api.nvim_buf_get_lines(self.inputBufnr, 0, 1, false)[1]
    onLeaveCmd()
    callback.onNewName(newName)
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
    callback = onLeaveCmd,
  })
  autocmd_id = api.nvim_create_autocmd({"WinLeave", "BufLeave"}, {
    buffer   = self.inputBufnr,
    callback = onLeaveCmd,
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
  api.nvim_buf_set_lines(inputBufnr, 0, -1, false, { currentTab.name })

  vim.bo[labelBufnr].modifiable = false
  vim.bo[labelBufnr].bufhidden  = "wipe"
  vim.bo[inputBufnr].bufhidden  = "wipe"

  api.nvim_win_set_cursor(inputWin, { 1, #currentTab.name+1 })
  api.nvim_feedkeys('a', 'i', true)

  local cleaned = false
  self:OnEnterCallback({
    onNewName = function(newName)
      self.dispatcher:emit(EVENTS.rename_finish, newName)
    end,
    onLeave   = function()
      if cleaned then return end
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
      api.nvim_win_set_cursor(termWinid, { 4,4 })
      self.cleaned = true
      self:Deactivate()
    end
  })
end

function NuiTermRename:Deactivate()
  self = NuiTermRename:new(self.dispatcher)
end

return NuiTermRename
