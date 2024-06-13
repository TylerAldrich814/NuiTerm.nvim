--> NuiTerm/utils.lua
--

local M = {}
local Debug = require("NuiTerm.Debug").Debug

M.WinHeight = 30

M.GetTermSize = function()
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

M.GetMousePos = function()
  return pcall(vim.fn.getmousepos)
end

M.WindowConfig = function(config)
  if not config then
    error("CONFIG IS NIL", 2)
  end

  local width    = config.width or vim.o.columns
  local height   = config.height or M.WinHeight
  local position = config.position or "bottom"
  local style    = config.style or "minimal"
  local border   = config.border or "rounded"
  local row, col = 0, 0

  if position == "bottom" then
    row = vim.o.lines - height - 4
  elseif position == "top" then
    row = 4
  else
    error("\n     - NuiTerm: setup.position --> Found an unknown value - \"" .. position .. "\"")
  end

  return {
    relative = "editor",
    width    = width,
    height   = height,
    style    = style,
    border   = border,
    row      = row,
    col      = col
  }
end

M.TabBarConfig = function(config)
  local winWidth  = config.width or vim.o.columns
  local winHeight = config.height or M.WinHeight
  local position  = config.position or "bottom"

  local tabRow = 0
  if position == "bottom" then
    tabRow = vim.o.lines - winHeight - 5
  elseif position == "top" then
    tabRow = 3
  end

  return {
    MainBar = {
      relative = "editor",
      width     = winWidth,
      height    = 1,
      row       = tabRow,
      col       = 0,
      style     = "minimal",
      border    = "none",
      focusable = false,
    },
    Tab = {
      col = 0,
      row = tabRow,
      width  = 20,
      height = 1,
    },
  }
end

M.PreventFileOpenInTerm = function(bufnr)
  local blocked_cmds = {"edit", "e", "split", "sp", "vsplit", "vsp", "tabedit", "tabe", "q", "q!"}
  local augroup = vim.api.nvim_create_augroup("PreventFileOpen", { clear = true })

  for _, cmd in ipairs(blocked_cmds) do
    vim.api.nvim_create_autocmd("BufEnter", {
      group = augroup,
      buffer = bufnr,
      callback = function()
        vim.api.nvim_buf_set_keymap(bufnr, "n", ":"..cmd, "<nop>", { noremap=true, silent=true })
        vim.api.nvim_buf_set_keymap(bufnr, "n", ":"..cmd.." ", "<nop>", { noremap=true, silent=true })
      end
    })
  end
  vim.api.nvim_buf_set_keymap(bufnr, "n", "o", "<nop>", { noremap=true, silent=true })
end

return M
