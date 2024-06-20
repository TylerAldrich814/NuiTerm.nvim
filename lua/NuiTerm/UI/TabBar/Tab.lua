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
local ends = {
  left  = "█", -- #left == 6
  lPad  = #"█"-4,
  right = "█",
  rPad  = #"█"-4,
}

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
    width     = width, --TODO: Remove '-2' once you get dynamic Tab Width established!
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

---@class SpecialChar
---@field char    string
---@field dWidth  number
---@field mWidth  number
---@field visible boolean
local SpecialChar = {}

function SpecialChar:new(char)
  local obj = setmetatable({
    char    = char,
    dWidth  = api.nvim_strwidth(char),
    mWidth  = #char,
    -- visible = true,
  }, { __index = self })
  return obj
end
function SpecialChar:Padding(length)
  local padding = string.rep(" ", length)
  local obj = setmetatable({
    char    = padding,
    dWidth  = #padding,
    mWidth  = #padding,
    -- visible = false,
  }, { __index = self })
  return obj
end

function SpecialChar:Debug()
  log("\"" ..self.char .. "\""  .. " dWidth:" .. self.dWidth .. " mWidth: " .. self.mWidth)
end

---@alias TabEnd {ch: string?, length: number}

---@type TabEnd
local rndLeft = {
  ch     =  "█",
  length = 2,
}
---@type TabEnd
local rndRight = {
  ch     =  "█",
  length = 2,
}
local sepCent = {
  ch = "|",
  length = 1,
}

local sep = "| "
local rndEnds = {
  "█","█"
}



local fgSel = pallet.autumnYellow
local bgSel = pallet.autumnRed

local fg    = pallet.waveBlue2
local bg1   = pallet.waveBlue1
local bg2   = pallet.sumiInk5

vim.api.nvim_set_hl(0, 'NTTabLineSel', { fg=fgSel, bg=bgSel, force = true })
vim.api.nvim_set_hl(0, 'NTTabLine',    { fg=fg,    bg=bg1, force = true })

vim.api.nvim_set_hl(0, 'NTTabRndSel',  { fg=bgSel, bg=bg2, force=true })
vim.api.nvim_set_hl(0, 'NTTabRnd',     { fg=bg1,   bg=bg2, force=true })

vim.api.nvim_set_hl(0, 'NTTabLineSep',    { fg = '#FFFFF0', bg = '#112244', force = true })
vim.api.nvim_set_hl(0, 'NTTabLineSepSel', { fg = '#112244', bg = '#FFFFF0', force = true })
vim.api.nvim_set_hl(0, "NTTabSep", { fg=fgSel, bg=bg1, force=true })

---@alias TabHLData {group: string, start: number, stop: number}

---@param bufnr number
---@param hlData TabHLData[]
function CreateTabHighlights(bufnr, hlData)
  for _, hl in ipairs(hlData)do
    api.nvim_buf_add_highlight(bufnr, 0, hl.group, 0, hl.start, hl.stop)
  end
end

---@param left     SpecialChar
---@param label    string
---@param right    SpecialChar
---@param tabWidth number
local function createTabLabel(left, label, right, tabWidth)
  local innerWidth = tabWidth - left.dWidth - right.dWidth
  if #label >= innerWidth-2 then
    local ellipsis = "... "
    label = fmt("%s%s", string.sub(label, 0, innerWidth-#label-#ellipsis), ellipsis)
  end
  local padding  = string.rep(" ", innerWidth - #label + 2) --  (right.visible and 2 or 3))
  local tabLabel = string.format("%s%s%s%s", left.char, label, padding, right.char)
  return tabLabel
end

function Tab:createFocusedTab()
  local leftChar  = SpecialChar:new("█")
  local rightChar = SpecialChar:new("█")
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
  local leftChar  = SpecialChar:new("█")
  local rightChar = SpecialChar:Padding(2)

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
      start = leftChar.mWidth + #string.format("%d", self.idx) + 2,
      stop  = -1,
    },{
      group = "NTTabSep",
      start = leftChar.mWidth,
      stop  = leftChar.mWidth + #string.format("%d", self.idx) + 2
    }}
  )
end

function Tab:createCenterTab()
  local leftChar  = SpecialChar:new("| ")
  local rightChar = SpecialChar:Padding(2)

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
      stop = leftChar.mWidth + #string.format(" %d", self.idx)+2
    }}
  )
end

function Tab:createRightWardTab()
  local leftChar  = SpecialChar:new("| ")
  local rightChar = SpecialChar:new("█")
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
      stop = leftChar.mWidth + #string.format(" %d", self.idx)+2
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

  if self.group == "NTTabLineSel" then -- Focus
    self:createFocusedTab()
  elseif self.idx == 1 then -- Left
    self:createLeftwardTab()
  elseif self.idx < self.totalTabs then -- Center
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
