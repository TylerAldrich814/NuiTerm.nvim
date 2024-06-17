--> NuiTerm/setup.lua
--
local Utils = require("NuiTerm.utils")
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


M.WindowConfig = function(config)
  if not config then
    error("CONFIG IS NIL", 2)
  end

  local position = config.position or "bottom"
  local width, col, _ = Utils.WidthPCT(config.width or vim.o.columns)
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
  local width, col, _ = Utils.WidthPCT(config.width or vim.o.columns)

  local height   = config.height or M.WinHeight
  local position = config.position or "bottom"

  local row  = 0
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
      col    = col,
      row    = row,
      width  = 25,
      height = 1,
      nuiWidth = width,
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
