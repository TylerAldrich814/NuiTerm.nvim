--> NuiTerm/Config/utils.lua
--
local WidthPCT = require("NuiTerm.Utils").WidthPCT
local Utils = {}

local log = require("NuiTerm.Debug").LOG_FN("ConfigUtil", {
  deactivated = true
})

---@param winConfig table
Utils.NuiTermMainWindowConfig = function(winConfig)
  if not winConfig then
    error("CONFIG IS NIL", 2)
  end

  local position = winConfig.position or "bottom"
  local width, col, _ = WidthPCT(winConfig.width or vim.o.columns)
  local row = 0

  if position == "bottom" then
    row = vim.o.lines - winConfig.height - 4
  elseif position == "top" then
    row = 4
  else
    error("- NuiTerm: setup.position --> Found an unknown value - \"" .. position .. "\"")
  end

  return {
    relative = "editor",
    width    = width,
    height   = winConfig.height,
    style    = winConfig.style,
    row      = row,
    col      = col,
    border   = "double",
    focusable = false,
  }
end

Utils.NuiTermShellConfig = function(winConfig, padding)
  if not winConfig then
    error("Shell Config is nil", 2)
  end
  local shellConfig = {
    relative = winConfig.relative,
    width    = winConfig.width,
    height   = winConfig.height,
    style    = winConfig.style,
    row      = winConfig.row,
    col      = winConfig.col,
    border   = "rounded",
    focusable = true,
  }

  local function updateRow(value)
    shellConfig.row = shellConfig.row + value/2
  end
  local function updateCol(value)
    shellConfig.col = shellConfig.col + value/2
  end
  local function updateWidth(value)
    shellConfig.width  = shellConfig.width - value --math.floor(value*2)
  end
  local function updateHeight(value)
    shellConfig.height  = shellConfig.height - value --math.floor(value*2)
  end

  if type(padding) == "number" then
    updateRow(padding)
    updateCol(padding)
    updateHeight(padding)
    updateWidth(padding)
  end
  if type(padding) == "table" then
    if padding.vertical then
      updateRow(padding.vertical/2)
      updateHeight(padding.vertical)
    else
      if padding.top and padding.bottom then
        updateRow(padding.top)
        updateHeight(padding.bottom)
      elseif padding.top then
        updateRow(padding.top)
        updateHeight(padding.top)
      elseif padding.bottom then
        updateRow(padding.bottom)
        updateHeight(padding.bottom)
      end
    end
    if padding.horizontal then
      updateCol(padding.horizontal)
      updateWidth(padding.horizontal)
    else
      if padding.left and padding.right then
        updateCol(padding.left)
        updateWidth(padding.right)
      elseif padding.left then
        updateCol(padding.left)
        updateWidth(padding.left)
      elseif padding.right then
        updateCol(padding.right)
        updateWidth(padding.right)
      end
    end
  end
  return shellConfig
end

Utils.NuitermTabBarConfig = function(tabConfig)
  local width, col, _ = WidthPCT(tabConfig.width or vim.o.columns)

  local height   = tabConfig.height or 1
  local position = tabConfig.position or "bottom"

  local row           = 0
  if position == "bottom" then
    row = vim.o.lines - height - 5
  elseif position == "top" then
    row = 3
  end

  return {
    MainBar = {
      relative  = "win",
      width     = 2, -- no border padding
      height    = 1,
      row       = row,
      col       = col,
      style     = "minimal",
      border    = "none",
      focusable = false,
    },
    Tab = {
      col      = col,
      row      = row,
      width    = 30,
      height   = 1,
      nuiWidth = width,
    },
  }
end

return Utils
