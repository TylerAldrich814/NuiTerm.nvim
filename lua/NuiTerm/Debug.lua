--> LuaTerm/Debug.lua
--

local debug_bufnr = nil
local debug_winid = nil

local function BufCheck()
  return debug_bufnr and vim.api.nvim_buf_is_valid(debug_bufnr)
end

local DebugConfig = {
  relative = "editor",
  width = 100,
  height = 40,
  row = 0,
  col = vim.o.columns - 103,
  border = "rounded",
  focusable = true,
};

local M = {}

M.FirstInit = true;
M.Messages = {}
M.StayClosed = true;

vim.keymap.set('n', '<leader>td', function() M.ToggleDebug() end, { noremap = true, silent = true})

function M.ToggleDebug()
  if M.StayClosed then
    M.StayClosed = false
    M.create_or_get_debug_window()
  else
    M.StayClosed = true
    M.hide_debug_window()
  end
end

local function OnResize()
  M.onResizeID = vim.api.nvim_create_autocmd('VimResized', {
    callback = function()
      vim.defer_fn(function()
        local width = vim.o.columns
        if width <= 100 then
          DebugConfig.width = 40
        elseif DebugConfig ~= 100 then
          DebugConfig.width = 100
        end
        DebugConfig.col = width - 100
        M.create_or_get_debug_window()
      end, 400)
    end
  })
end

-- Create or get the existing debug window
function M.create_or_get_debug_window()
  if M.StayClosed then
    return
  end
  if debug_winid and vim.api.nvim_win_is_valid(debug_winid) then
    return debug_winid, debug_bufnr
  end

  -- Create a new buffer if it doesn't exist
  if not debug_bufnr or not vim.api.nvim_buf_is_valid(debug_bufnr) then
    debug_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[debug_bufnr].bufhidden  = "wipe"
    vim.bo[debug_bufnr].filetype   = "debug"  -- Optional: Set a custom filetype
  end

  -- Create the floating window
  debug_winid = vim.api.nvim_open_win(debug_bufnr, true, DebugConfig)
  if M.FirstInit then
    M.FirstInit = false
    M.Push(" <-- NuiTerm Debug Window -->")
  else
    vim.api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, M.Messages)
  end

  OnResize()

  return debug_winid, debug_bufnr
end

function M.hide_debug_window()
  if debug_winid and vim.api.nvim_win_is_valid(debug_winid) then
    vim.api.nvim_win_hide(debug_winid)
    vim.api.nvim_del_autocmd(M.onResizeID)
    debug_winid = nil
  end
end

function M.Push(msg)
  table.insert(M.Messages, msg) -- Insert Messages into memory, even if Debug window is hidden
  if not BufCheck()then
    return
  end
  if debug_bufnr then
    vim.api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, {msg})
  end
end

-- Push a message to the debug window
function M.push_message(source, msg)
  M.create_or_get_debug_window()
  local message = "["..source.."]".." :: " .. msg
  -- M.Push(message)
  table.insert(M.Messages, message) -- Insert Messages into memory, even if Debug window is hidden
  if not BufCheck()then
    return
  end
  if debug_bufnr then
    vim.api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, {message})
  end
end

-- Log Funciton Factory
-- usage: 
--    local Debug = require("NuiTerm.Debug")
--    local log = Debug.LOG_FN("<Source>", {
--      deactivate = false,
--    })
--    ..
--    log("Something Happened", "SomeFunc")
function M.LOG_FN(SOURCE, opts)
  return function(msg, src)
    local source = SOURCE
    if src then
      source = source .. ":" .. src
    end
    if M.StayClosed then return end
    if opts then
      if opts.deactivate then
        return
      end
    end
    M.push_message(source, msg)
  end
end

return M
