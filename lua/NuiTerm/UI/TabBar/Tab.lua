--> Nuimerm/TabBar/Tab.lutabWidth
--
local fmt = string.format

local pallet = require("NuiTerm.Theme.colors").palette
local log = require("NuiTerm.Debug").LOG_FN("Tab", {
  deactivate = false,
})
local api = vim.api

local seps = {
  left =  "▎",
  right = "🮇",
}

local fgSel = pallet.autumnYellow
local bgSel = pallet.autumnRed

local fg    = pallet.waveBlue2
local bg1   = pallet.waveBlue1
local bg2   = pallet.sumiInk5

---@enum nuiterm.NTGroups
local NTGroups = {
  NTTabLineSel    = "NTTablineSel",
  NTTabLine       = "NTTabLine",
  NTTabRndSel     = "NTTabRndSel",
  NTTabRnd        = "NTTabRnd",
  NTTabLineSep    = "NTTabLineSep",
  NTTabLineSepSel = "NTTabLineSepSel",
  NTTabSep        = "NTTabSep",
}

vim.api.nvim_set_hl(0, NTGroups.NTTabLineSel,    { fg=fgSel, bg=bgSel, force = true })
vim.api.nvim_set_hl(0, NTGroups.NTTabLine,       { fg=fg,    bg=bg1, force = true })

vim.api.nvim_set_hl(0, NTGroups.NTTabRndSel,     { fg=bgSel, bg=bg2, force=true })
vim.api.nvim_set_hl(0, NTGroups.NTTabRnd,        { fg=bg1,   bg=bg2, force=true })

vim.api.nvim_set_hl(0, NTGroups.NTTabLineSep,    { fg = '#FFFFF0', bg = '#112244', force = true })
vim.api.nvim_set_hl(0, NTGroups.NTTabLineSepSel, { fg = '#112244', bg = '#FFFFF0', force = true })
vim.api.nvim_set_hl(0, NTGroups.NTTabSep,        { fg=fgSel, bg=bg1, force=true })

---@class NTChar
---@field char    string
---@field dWidth  number
---@field mWidth  number
---@field group   string
local NTChar={  }

function NTChar:new(char)
  local obj = setmetatable({
    char    = char,
    dWidth  = api.nvim_strwidth(char),
    mWidth  = #char,
  }, { __index = self })
  return obj
end

function NTChar:newG(char, group)
  local obj = setmetatable({
    char    = char,
    dWidth  = api.nvim_strwidth(char),
    mWidth  = #char,
    group   = group,
  }, { __index = self })
  return obj
end

function NTChar:Padding(length)
  local padding = string.rep(" ", length)
  local obj = setmetatable({
    char    = padding,
    dWidth  = #padding,
    mWidth  = #padding,
  }, { __index = self })
  return obj
end

function NTChar:Debug()
  log("\"" ..self.char .. "\""  .. " dWidth:" .. self.dWidth .. " mWidth: " .. self.mWidth)
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

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
    width     = width,
    height    = height,
    tabName   = nil,
  }
end

---@class Tab
---@field bufnr     number
---@field winid     number
---@field config    table
---@field name      string
---@field label     string
---@field group     string
---@field idx       number
---@field totalTabs number
local Tab = { }

---@param idx      number
---@param name     string
---@param col      number
---@param width    number
---@param height   number
function Tab:new(
  idx,
  name,
  col,
  width,
  height,
  mainWinId,
  totalTabs,
  focused
)
  local group = "NTTabLine"
  if focused then group = "NTTabLineSel" end
  local obj = setmetatable({
    bufnr  = api.nvim_create_buf(false, true),
    winid  = nil,
    config = TabConfig(mainWinId, col, width, height),
    name   = name,
    label  = string.format("%d %s%s", idx, seps.left, name),
    group  = group,
    idx    = idx,
    totalTabs = totalTabs,
  }, {__index = self})

  vim.bo[obj.bufnr].bufhidden = "hide"
  return obj
end

---@alias TabHLData {group: string, start: number, stop: number}

---@param bufnr number
---@param hlData TabHLData[]
function CreateTabHighlights(bufnr, hlData)
  for _, hl in ipairs(hlData)do
    api.nvim_buf_add_highlight(bufnr, 0, hl.group, 0, hl.start, hl.stop)
  end
end

---@param left     NTChar
---@param label    string
---@param right    NTChar
---@param tabWidth number
local function createTabLabel(left, label, right, tabWidth)
  local innerWidth = tabWidth - left.dWidth - right.dWidth
  if #label >= innerWidth then
    local ellipsis = "... "
    label = fmt("%s%s", string.sub(label, 0, innerWidth-#label-#ellipsis), ellipsis)
  end
  local padding  = string.rep(" ", innerWidth - #label + 2)
  local tabLabel = string.format("%s%s%s%s", left.char, label, padding, right.char)
  return tabLabel
end

function Tab:IDString()
  return fmt(" %d ", self.idx)
end

function Tab:createFocusedTab()
  local leftChar  = NTChar:new("█")
  local rightChar = NTChar:new("█")
  self.config.zindex = self.config.zindex+5
  self.config.width  = self.config.width+1

  local label = createTabLabel(leftChar, self.label, rightChar, self.config.width)

  self.winid = api.nvim_open_win(self.bufnr, false, self.config)
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { label })
  CreateTabHighlights(
    self.bufnr,
    {{
      group = "NTTabLineSel",
      start = 0,
      stop = -1,
    },
    {
      group = "NTTabRndSel",
      start = 0,
      stop = leftChar.mWidth,
    },
    {
      group = "NTTabRndSel",
      start = #label - rightChar.mWidth,
      stop = -1
    }
    }
  )
end


function Tab:createLeftwardTab()
  local leftChar  = NTChar:new("█")
  local rightChar = NTChar:Padding(2)

  local label = createTabLabel(leftChar, self.label, rightChar, self.config.width)

  log("origLeft: \"" .. label .. "\"")

  self.winid = api.nvim_open_win(self.bufnr, false, self.config)
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { label })
  CreateTabHighlights(
    self.bufnr,
    {{
      group = "NTTabRnd",
      start = 0,
      stop  = leftChar.mWidth,
    },{
      group = "NTTabLine",
      start = leftChar.mWidth + #self:IDString(),
      stop  = -1,
    },{
      group = "NTTabSep",
      start = leftChar.mWidth,
      stop  = leftChar.mWidth + #self:IDString()
    }}
  )
end

function Tab:createCenterTab()
  local leftChar  = NTChar:new("| ")
  local rightChar = NTChar:Padding(2)

  local label = createTabLabel(leftChar, self.label, rightChar, self.config.width)

  self.winid = api.nvim_open_win(self.bufnr, false, self.config)
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { label })
  CreateTabHighlights(
    self.bufnr,
    {{
      group = "NTTabLine",
      start = 0, stop = -1
    },
    {
      group = "NTTabSep",
      start = 0,
      stop = leftChar.mWidth,
    },{
      group = "NTTabSep",
      start = leftChar.mWidth,
      stop = leftChar.mWidth + #self:IDString()
    }}
  )
end

function Tab:createRightWardTab()
  local leftChar  = NTChar:new("| ")
  local rightChar = NTChar:new("█")
  local label = createTabLabel(leftChar, self.label, rightChar, self.config.width)

  log("origRigh: \"" .. label .. "\"")

  self.winid = api.nvim_open_win(self.bufnr, false, self.config)
  api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { label })
  CreateTabHighlights(
    self.bufnr,
    {{
      group = "NTTabLine",
      start = 0, stop = -1,
    },{
      group = "NTTabRnd",
      start = #label-rightChar.mWidth,
      stop = -1
    },{
      group = "NTTabSep",
      start = 0,
      stop = leftChar.mWidth + #self:IDString()
    }}
  )
end

---@param from number
---@param to   number
function Tab:hlAccent(from, to)
  api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabSep", 0, from, to)
end

function Tab:Display()
  self.config.focusable = true
  api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)

  if self.group == "NTTabLineSel" then   -- Focus
    self:createFocusedTab()
  elseif self.idx == 1 then              -- Left
    self:createLeftwardTab()
  elseif self.idx < self.totalTabs then  -- Center
    self:createCenterTab()
  elseif self.idx == self.totalTabs then -- Right
    self:createRightWardTab()
  end

  return self
end

function Tab:Hide()
  api.nvim_win_hide(self.winid)
  self.winid = nil
end

return Tab
