--> NuiTerm/Term.lua
--
local Utils   = require("NuiTerm.utils")
local Debug   = require("NuiTerm.Debug")
local Keymaps = require("NuiTerm.Keymap.Term")
local api, fn     = vim.api, vim.fn

local log = Debug.LOG_FN("TermWindow", {
  deactivate = false,
})

---@class TermWindow
local TermWindow = {  }

-- Function to Create a new Termianl Instance
---@param termid number
---@param config table
function TermWindow:Init(termid, config)
  local obj = setmetatable({
    bufnr        = nil,
    winid        = nil,
    termid       = nil,
    name         = "NuiTerm",
    curLineCount = 0,
    config       = {},
    onHide       = nil,
    showing      = false,
    spawned      = false,
  }, { __index = self })
  obj.termid = termid
  obj.config = config
  local bufnr = vim.api.nvim_create_buf(false, true)

  vim.bo[bufnr].bufhidden  = "hide"
  vim.bo[bufnr].buftype    = "acwrite"
  vim.bo[bufnr].modifiable = false

  obj.bufnr       = bufnr
  obj.initialized = true
  Utils.PreventFileOpenInTerm(obj.bufnr)
  return obj
end

function TermWindow:IsBufValid()
  local valid = self.bufnr and api.nvim_buf_is_valid(self.bufnr)
  if not valid then
    log("Bufnr was somehow deleted!", "IsBufValid")
    return false
  end
  return true
end

function TermWindow:RecreateBuf()
  if not self:IsBufValid() then
    local bufnr = api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = 'wipe'
    self.bufnr = bufnr
    self.spawned = false
  end
end

function TermWindow:SpawnShell()
  if self.spawned then
    log("Already spawned ID: " .. self.termid, "SpawnShell")
    return
  end
  fn.termopen(vim.o.shell, {
    bufnr = self.bufnr,
    on_exit = function()
      log("ON_EXIT!", "SpawnShell")
    end,
  })
  self.spawned = true
end

function TermWindow:Show()
  self:RecreateBuf()
  if not self.config then
    error("TermWindow:Show(): Self.config is nil", 2)
  end
  local winid = api.nvim_open_win(self.bufnr, true, self.config)
  vim.wo[winid].winfixbuf = true -- Disables loading files in TermWindow

  self.winid  = winid
  self:SpawnShell()
  self.showing = true;
  Keymaps.AddTermKeyMaps(self.bufnr)

  return winid
end

---@param bufnr    number
---@param fallback number
local function getLastNonEmptyLine(bufnr, fallback)
  local line_count = api.nvim_buf_line_count(bufnr)
  for i = line_count, 1, -1 do
    local line = api.nvim_buf_get_lines(bufnr, i-1, i, false)[1]
    if line and line:match("%s") then
      return i
    end
  end
  return fallback
end

--- If the current Buffer line count is greate than the NuiTerm window height,
--- then we move the cursor to the last line of the buffer.
function TermWindow:MoveToLastLine()
  api.nvim_win_set_cursor(
    self.winid, {
      getLastNonEmptyLine(self.bufnr,4), 4
    }
  )
end

function TermWindow:Hide()
  if not self.winid or not api.nvim_win_is_valid(self.winid) then
    return
  end
  Keymaps.RemoveTermKeymaps(self.bufnr)
  self.showing = false;
  api.nvim_win_hide(self.winid)
  self.winid = nil
end

function TermWindow:Delete()
  self:Hide()
  self.bufnr = nil
  self.termid = nil
end

---@param config table
function TermWindow:UpdateConfig(config)
  self.config = config
end

return TermWindow
