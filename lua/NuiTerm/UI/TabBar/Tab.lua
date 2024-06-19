--> Nuimerm/TabBar/Tab.lua
--

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

---@alias TabEnd {ch: string, length: number}

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
---@type TabEnd
local sepLeft = {
  ch = "▎",
  length = 1,
}
---@type TabEnd
local sepRight = {
  ch = "",
  length = 0
  -- ch = "🮇",
  -- length = 1
}

local sepCent = {
  ch = "|",
  length = 1,
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

function Tab:Display()
  log("Name: \"" .. self.label .. "\"")
  self.config.focusable = true
  local rawName = self.label
  local tabWidth = self.config.width

  local function ellipsis(label, cutoff)
    return string.format("%s... ", string.sub(label, 0, cutoff))
  end

  ---@param from number
  ---@param to   number
  local function hlAccent(from, to)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabSep", 0, from, to)
  end

  api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
  if self.group == "NTTabLineSel" then -- Focus
    local left, right  = rndLeft.length, rndRight.length
    local innerWidth = tabWidth - left - right
    if #rawName >= innerWidth then
      rawName = ellipsis(rawName, innerWidth-#rawName-#"... ")
    end
    local padding = string.rep(" ", innerWidth - #rawName + 2)
    rawName = string.format("%s%s%s%s", rndLeft.ch, rawName, padding, rndRight.ch)

    self.winid = api.nvim_open_win(self.bufnr, false, self.config)
    api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { rawName })

    log(" Focus: \"".. rawName .. "\"")

    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabLineSel", 0, 0, -1)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabRndSel", 0, 0, #rndLeft.ch)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabRndSel", 0, #rawName-#rndRight.ch, -1)

  elseif self.idx == 1 then -- Left
    local left, right  = rndLeft.length, rndRight.length
    local innerWidth = tabWidth - left
    if #rawName >= innerWidth then
      rawName = ellipsis(rawName, innerWidth-#rawName-#"... ")
    end
    local padding = string.rep(" ", innerWidth - #rawName + right + 2)
    rawName = string.format("%s%s%s", rndLeft.ch, rawName, padding)
    self.winid = api.nvim_open_win(self.bufnr, false, self.config)
    api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { rawName })

    log("  Left: \"".. rawName .. "\"")

    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabRnd", 0, 0, #rndLeft.ch)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabRnd", 0, 0, #rndLeft.ch)

    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabLine", 0, #rndLeft.ch, -1)

    hlAccent(#rndLeft.ch, #rndLeft.ch + #string.format("%d", self.idx) + 2)

  elseif self.idx < self.totalTabs then -- Center
    local left = sepCent.length
    local right = sepRight.length
    local innerWidth = tabWidth - left - right
    if #rawName >= innerWidth then
      rawName = ellipsis(rawName, innerWidth-#rawName-#"... ")
    end
    local padding = string.rep(" ", innerWidth - #rawName + right)
    rawName = string.format("%s %s%s%s", sepCent.ch, rawName, padding, sepCent.ch)

    self.winid = api.nvim_open_win(self.bufnr, false, self.config)
    api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { rawName })

    log("Center: \"".. rawName .. "\"")

    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabLine", 0, 0, -1)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabSep", 0, 0, #sepCent.ch)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabSep", 0, #rawName-#sepCent.ch, -1)

    hlAccent(#sepCent.ch, #sepCent.ch + #string.format(" %d", self.idx) + 2)

  elseif self.idx == self.totalTabs then -- Right
    local left, right  = rndLeft.length, rndRight.length
    local innerWidth = tabWidth - left
    if #rawName >= innerWidth then
      rawName = ellipsis(rawName, innerWidth-#rawName-#"... ")
    end

    local left_pad = string.rep(" ", rndLeft.length)
    local right_pad  = string.rep(" ", innerWidth - #rawName + right - rndRight.length)
    log("lPad: " .. #left_pad)
    log("rPad: " .. #right_pad)
    rawName = string.format("%s%s%s%s", left_pad, rawName, right_pad, rndRight.ch)

    self.winid = api.nvim_open_win(self.bufnr, false, self.config)
    api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { rawName })

    log("  Left: \"".. rawName .. "\"")

    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabLine", 0, 0, -1)
    api.nvim_buf_add_highlight(self.bufnr, 0, "NTTabRnd", 0, #rawName-#rndRight.ch, -1)

    hlAccent(rndLeft.length, rndLeft.length + #string.format("%d", self.idx) + 1)
  end

  return self
end

-- Formats self.name into the Displayed name in the Tab.
-- If the chosen name does not fit wihtin the constrains 
-- set forth by tab.config.width.
-- If self.name is too long, we splice and add an elipsis
-- before adding it to the UI
----@param idx number
----@param total_tabs number
-- function Tab:XCompileName(idx, total_tabs)
--   local width = self.config.width
--   local left, right = self.ends.left, self.ends.right
--   local tabName = string.format("%d ▎%s", self.idx, self.name)
--   local padding = width - #tabName - 4
--   if padding >= 9 then
--     tabName = string.format("%s%s", tabName, string.rep(" ", padding))
--   else
--     tabName = string.format("%s...  ",string.sub(tabName, 0, width-9))
--   end
--   -- return tabName
--   -- string.format("%s %s %s ", left, tabName, right)
--   log("IDX: " .. idx .. " TotalTabs: " .. total_tabs)
--   local name = ""
--
--   log("Left: " .. #self.ends.left)
--   log("Righ: " .. #self.ends.right)
--
--   if total_tabs == 1 then
--     name = string.format("%s %s %s ", left, tabName, right)
--   elseif idx > 1 and idx < total_tabs then
--     name = string.format("   $s   ", tabName)
--   elseif idx == total_tabs then
--     name = string.format("   $s $s", tabName, left)
--   end
--   log("TabName[ "..#name.." ]: \""..name.. "\"")
--
--   return name
-- end


-- ---@param total_tabs number
-- function Tab:CompileName(total_tabs)
--   local tabWidth = self.config.width
--   local left, right = self.ends.left, self.ends.right
--   local sepPadding = #'▎'-1
--   local rawName = string.format("%d ▎%s", self.idx, self.name)
--
--   log("self.idx: " .. self.idx)
--
--   -- focused
--   if self.group == "NTTabLineSel" then
--     local difference = tabWidth - #rawName+sepPadding - self.ends.lPad - self.ends.rPad
--     self.config.zindex = self.config.zindex+1
--     -- return string.format("%s%s%s%s", left, rawName, string.rep(" ", difference), right)
--     return {
--       lPad  = ends.lPad,
--       label = string.format("%s%s%s%s", left, rawName, string.rep(" ", difference), right),
--       rPad  = ends.rPad,
--     }
--   end
--
--   -- first unforcused
--   if self.idx == 1 then
--     local difference = tabWidth - #rawName+sepPadding - self.ends.lPad + self.ends.rPad + self.ends.lPad
--     self.config.width = self.config.width+3
--     -- return string.format("%s%s%s", left, rawName, string.rep(" ", difference))
--     return {
--       lPad  = ends.lPad,
--       label = string.format("%s%s%s", left, rawName, string.rep(" ", difference)),
--       rPad  = -1
--     }
--   end
--
--   -- center unforcused
--   if self.idx < total_tabs then
--   local difference = tabWidth - #rawName+sepPadding + self.ends.lPad + self.ends.rPad
--   return string.format("%s%s%s", string.rep(" ", self.ends.lPad), rawName, string.rep(" ", difference))
--   end
--
--   -- last
--   local difference = tabWidth - #rawName+sepPadding - self.ends.lPad
--   return string.format("%s%s%s", rawName, string.rep(" ", difference), right)

  -- local difference = tabWidth - #rawName+sepPadding - self.ends.lPad - self.ends.rPad
  -- return string.format("%s%s%s%s", left, rawName, string.rep(" ", difference), right)
-- end

-- ---@param onClick    function
-- ---@param group      string
-- ---@param total_tabs number
-- function Tab:xDisplay(onClick, group, total_tabs)
--   if not api.nvim_buf_is_valid(self.bufnr) then
--     log("self.bufnr not a valid bufnr: "..self.bufnr)
--   end
--
--   self.group = group
--   self.tabName = self:CompileName(total_tabs)
--
--   self.winid = api.nvim_open_win(self.bufnr, false, self.config)
--   api.nvim_buf_set_lines(self.bufnr, 0, -1, false, { self.name })
--
--   -- RightMouse kepmapping NOT WORKING
--   api.nvim_buf_set_keymap(self.bufnr, 'n', '<RightMouse>', '', {
--     callback = function()
--       log("Clicked on \"" .. self.name .. "\"")
--       onClick()
--     end,
--     noremap = true,
--     silent  = true,
--   })
--
--   api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
-- end

-- function Tab:Highlight()
--   api.nvim_buf_clear_namespace(self.bufnr, 0, 0, -1)
--   local border = ""
--   local group = self.group
--   if group == "NTTabLineSel" then
--     border = "NTTabLine"
--   else
--     border = "NTTabLineSel"
--   end
--   local ends = self.ends
--   local endLen = #ends.left
--   local namelength = #self.tabName - #ends.left
--   api.nvim_buf_add_highlight(self.bufnr, 0, group,  0, 0, -1)
--   api.nvim_buf_add_highlight(self.bufnr, 0, border, 0, 0, endLen) -- left
--   api.nvim_buf_add_highlight(self.bufnr, 0, border, 0, namelength, -1) -- right
-- end

function Tab:Hide()
  log("HIDE TAB")
  api.nvim_win_hide(self.winid)
  self.winid = nil
end

return Tab
