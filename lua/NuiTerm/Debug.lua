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
  -- focusable = false,
};

local M = {}

M.FirstInit = true;
M.Messages = {}

function M.Push(msg)
  table.insert(M.Messages, msg) -- Insert Messages into memory, even if Debug window is hidden
  if not BufCheck()then
    return
  end
  vim.api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, {msg})
end

-- Create or get the existing debug window
function M.create_or_get_debug_window()
  if debug_winid and vim.api.nvim_win_is_valid(debug_winid) then
    return debug_winid, debug_bufnr
  end

  -- Create a new buffer if it doesn't exist
  if not debug_bufnr or not vim.api.nvim_buf_is_valid(debug_bufnr) then
    debug_bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[debug_bufnr].bufhidden = "wipe"
    vim.bo[debug_bufnr].filetype = "debug"  -- Optional: Set a custom filetype
  end

  -- Create the floating window
  debug_winid = vim.api.nvim_open_win(debug_bufnr, true, DebugConfig)
  if M.FirstInit then
    M.FirstInit = false
    M.Push(" <-- NuiTerm Debug Window -->")
  else
    vim.api.nvim_buf_set_lines(debug_bufnr, -1, -1, false, M.Messages)
  end

  return debug_win_id, debug_bufnr
end

-- Push a message to the debug window
function M.push_message(source, msg)
  M.create_or_get_debug_window()
  local message = "["..source.."]".." :: " .. msg
  M.Push(message)
end

-- Hide the debug window
function M.hide_debug_window()
  if debug_winid and vim.api.nvim_win_is_valid(debug_winid) then
    vim.api.nvim_win_hide(debug_winid)
    debug_winid = nil
  end
end

return M