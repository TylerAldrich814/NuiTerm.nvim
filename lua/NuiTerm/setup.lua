--> NuiTerm/setup.lua
--
local defaultSettings = require("NuiTerm.defaults")
local M = {}

M.NSID = vim.api.nvim_create_namespace("NuiTerm")
M.WinHeight = 30

local function mergeConfigs(defaults, overrides)
  for k, v in pairs(defaults) do
    if type(v) ~= "table" then
      overrides[k] = overrides[k] or v
      goto continue
    end

    if not overrides[k] then
      overrides[k] = v
    elseif type(overrides[k]) ~= 'table' then
      error("Keymap: \""..k.." should be a table")
    end
    overrides[k] = mergeConfigs(v, overrides[k])
    ::continue::
  end
  return overrides
end

---@param width number|string
local function WidthPCT(width)
  if type(width) == "number" then
    print("Widht is a number: " .. width)
    return width, 0, 0
  end
  local termWidth = vim.o.columns
  local winCol   = 0
  local tabCol   = 0
  local nuiWidth = 0

  if type(width) == "string" then
    local num, den = string.match(width, "^(%d+)/(%d+)$")
    if not num or not den then
      print("win_config.width: Found to be a string. But was not a valid width command: \""..width.."\"")
      width = termWidth
      return termWidth, winCol, tabCol
    end

    num, den = tonumber(num), tonumber(den)
    if num > den then
      width = termWidth
      print("win_config.width: Found to be a percentage command. But width > 1.0 : \""..width.."\"")
      return termWidth, winCol, tabCol
    end

    nuiWidth = math.floor(termWidth * (num/den))
    if termWidth % 2 == 1 and nuiWidth % 2 == 0 then
      nuiWidth = nuiWidth + 1
      tabCol = 2
    elseif termWidth % 2 == 0 and nuiWidth % 2 == 1 then
      nuiWidth = nuiWidth - 1
      tabCol = -2
    end
    winCol = math.ceil(termWidth/2) - math.floor(nuiWidth/2)
    tabCol = tabCol + winCol
    width = nuiWidth
  end
  print("- TermWidth: " .. termWidth)
  print("-  nuiWidth: " .. nuiWidth)
  print("-    winCol: " .. winCol)
  print("-    tabCol: " .. tabCol)
  return nuiWidth, winCol, tabCol
end

M.WindowConfig = function(config)
  if not config then
    error("CONFIG IS NIL", 2)
  end

  local position = config.position or "bottom"
  local width, col, _ = WidthPCT(config.width or vim.o.columns)
  local row = 0

  if position == "bottom" then
    row = vim.o.lines - config.height - 4
  elseif position == "top" then
    row = 4
  else
    error("\n     - NuiTerm: setup.position --> Found an unknown value - \"" .. position .. "\"")
  end

  return {
    relative = "editor",
    width    = width,
    height   = config.height,
    style    = config.style,
    border   = config.border,
    row      = row,
    col      = col
  }
end

M.TabBarConfig = function(config)
  local width, col, _ = WidthPCT(config.width or vim.o.columns)

  local height = config.height or M.WinHeight
  local position  = config.position or "bottom"

  local row  = 0
  if position == "bottom" then
    row = vim.o.lines - height - 5
  elseif position == "top" then
    row = 3
  end

  return {
    MainBar = {
      relative  = "editor",
      width     = width+2, -- no border padding
      height    = 1,
      row       = row,
      col       = col,
      style     = "minimal",
      border    = "none",
      focusable = false,
    },
    Tab = {
      col    = col,
      row    = row,
      width  = 20,
      height = 1,
    },
  }
end

function M.setup(opts)
  local user_keymaps    = opts.user_keymaps or {}
  local user_win_config = opts.win_config or {}

  local key = mergeConfigs(defaultSettings.keyMaps, user_keymaps)
  local win = mergeConfigs(defaultSettings.winConfig(), user_win_config)

  M.keyMaps   = key
  M.winConfig = M.WindowConfig(win)
end

return M
