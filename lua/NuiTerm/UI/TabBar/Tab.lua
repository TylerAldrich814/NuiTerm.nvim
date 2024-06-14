--> NuiTerm/TabBar/Tab.lua
--
local Utils = require("NuiTerm.utils")
local log = require("NuiTerm.Debug").LOG_FN("Tab", {
  deactivate = false,
})
local api = vim.api

---@param mainWinId number
---@param col       number
---@param width     number
---@param height    number
local function TabConfig(mainWinId, col, width, height)
  return {
    relative  = "win",
    win       = mainWinId,
    style     = "minimal",
    border    = "none",
    zindex    = 100,
    focusable = false,
    col       = col,
    row       = -1,
    width     = width-2, --TODO: Remove '-2' once you get dynamic Tab Width established!
    height    = height,
  }
end

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
  idx    = 0,
}

---@param idx      number
---@param name     string
---@param col      number
---@param width    number
---@param height   number
function Tab:New(
  idx,
  name,
  col,
  width,
  height,
  mainWinId
)
  local obj = setmetatable({}, {__index = self})
  obj.name = name
  obj.bufnr = vim.api.nvim_create_buf(false, true)
  obj.config = TabConfig(mainWinId, col, width, height)
  obj.idx = idx

  vim.bo[obj.bufnr].buftype = "nofile"
  vim.bo[obj.bufnr].bufhidden = "hide"
  -- Utils.PreventFileOpenInTerm(obj.bufnr)
  return obj
end

function Tab:CompileName()
  -- |     <tab-width>     |
  -- if - MyLongTerminalName
  -- |  1 - MyLongTerm...  |
  -- if - Terminal
  -- |  1 - Termianl       |
  local width = self.config.width
  local tabName = string.format("  %d - %s", self.idx, self.name)
  local padding = width - #tabName
  if padding >= 2 then
    tabName = string.format("%s%s", tabName, string.rep(" ", padding))
  else
    --- Cut last 3 characters of tabName, add '...' and 2 spaces
    tabName = string.format("%s...  ",string.sub(tabName, 0, width-5))
  end

  return tabName
end

---@param onClick function
function Tab:Display(onClick)
  if not vim.api.nvim_buf_is_valid(self.bufnr) then
    log("self.bufnr not a valid bufnr: "..self.bufnr)
  end

  self.winid = vim.api.nvim_open_win(self.bufnr, false, self.config)
  -- vim.wo.winfixbuf = true

  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { 
    -- self.name 
    self:CompileName()
  })

  -- RightMouse kepmapping NOT WORKING
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

function Tab:Rename()
  log("Renaming", "Rename")
  local store_bufnr = api.nvim_get_current_buf()
  local store_winid = api.nvim_get_current_win()

  api.nvim_win_set_cursor(self.winid, {1, 0})
  -- vim.api.nvim_feedkeys('i', 'n', true)
  -- api.nvim_feedkeys(api.nvim_replace_termcodes('<Esc>^', true, false, true).. 'ce', 'm', false)

  -- api.nvim_create_autocmd('BufLeave', {
  --   buffer = store_bufnr,
  --   callback = function()
  --     local new_name = api.nvim_buf_get_lines(store_bufnr, 0, 1, false)[1]
  --     self.name = new_name
  --   end,
  --   once = true
  -- })

end

return Tab
