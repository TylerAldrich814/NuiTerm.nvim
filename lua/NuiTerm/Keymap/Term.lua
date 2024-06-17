--> NuiTerm/Keymap/term.lua
--
local api = vim.api
local M = {}

---@param bufnr number
M.AddTermKeyMaps = function(bufnr)
  -- When the user moves the focus from the NuiTerm Window to another neovim window,
  -- we call this autocmd. Which in turn calls our 'onLeave' callback, i.e., MainWindow:Hide()
  --TODO: We need to somehow detect if the focus left both the Term window AND the tabs window(s)
  --      This might require returning a paramter to 'onLeave' Telling MainWindow:Hide() which function
  --      called it( since we have a handful of functions that call Hide) That way if we tell onLeave that
  --      this AutoCMD is calling it, ff we can then detect if our focus is on the tabbar or not.

  -- When moving outside of NuiTerm Bufnr
  -- autocmdid = api.nvim_create_autocmd({ "WinLeave" }, {
  --   buffer = bufnr,
  --   callback = function()
  --     if showing and winid and api.nvim_win_is_valid(winid) then
  --       onLeave()
  --     end
  --   end
  -- })

  -- Mode Keymaps
  --- If in 'terminal' mode, Hitting <Esc> will call MainWindow:NormMode -- Putting you into Normal Mode
  -- [[<cmd>lua require('NuiTerm').MainWindow:NormMode()<CR>]],
  api.nvim_buf_set_keymap(
    bufnr,
    't',
    '<Esc>',
    [[<cmd>lua require('NuiTerm').eventController.nuiTermWindow:NormMode()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )

  -- api.nvim_buf_set_keymap(
  --   bufnr,
  --   "i",
  --   "<LeftDrag>",
  --   "<nop>",
  --   { noremap = true, silent = true }
  -- )
  -- api.nvim_buf_set_keymap(
  --   bufnr,
  --   "i",
  --   "<LeftRelease>",
  --   "<nop>",
  --   { noremap = true, silent = true }
  -- )
  --
  local insert_commands = { "i", "<S-i>", "a", "<S-a>" }
  -- If in 'Normal' mode, Hitting 'i' will call MainWindow:TermMode -- Putting you into TerminalMode
  for _, cmd in ipairs(insert_commands) do
    api.nvim_buf_set_keymap(
      bufnr,
      'n',
      cmd,
      [[<cmd>lua require('NuiTerm').eventController.nuiTermWindow:TermMode()<CR>]],
      {
        noremap = true,
        silent  = true,
      }
    )
  end
  -- If in 'Normal' mode, Hitting <Esc> will call MainWindow:Hide() -- Hiding the NuiTerm Window
  api.nvim_buf_set_keymap(
    bufnr,
    'n',
    "<Esc>",
    [[<cmd>lua require('NuiTerm').eventController:Hide()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )
  api.nvim_buf_set_keymap(
    bufnr,
    'n',
    -- require('NuiTerm').keyMaps.next_term,
    require('NuiTerm').eventController.ntConfigHandler.keymaps.next_term,
    [[<cmd>lua require('NuiTerm').eventController:NextTerm()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )
  api.nvim_buf_set_keymap(
    bufnr,
    'n',
    require('NuiTerm').eventController.ntConfigHandler.keymaps.prev_term,
    [[<cmd>lua require('NuiTerm').eventController:PrevTerm()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )
  api.nvim_buf_set_keymap(
    bufnr,
    'n',
    require('NuiTerm').eventController.ntConfigHandler.keymaps.close_term,
    [[<cmd>lua require('NuiTerm').eventController:DelTerm()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )

  local resizeCmd = { 'n', 'i' }
  for _, cmd in pairs(resizeCmd) do
    api.nvim_buf_set_keymap(
      bufnr,
      cmd,
      require('NuiTerm').eventController.ntConfigHandler.keymaps.term_resize.expand.cmd,
      [[<cmd>lua require('NuiTerm').Expand()<CR>]],
      {
        noremap = true,
        silent  = true,
      }
    )
    api.nvim_buf_set_keymap(
      bufnr,
      cmd,
      require('NuiTerm').eventController.ntConfigHandler.keymaps.term_resize.shrink.cmd,
      [[<cmd>lua require('NuiTerm').Shrink()<CR>]],
      {
        noremap = true,
        silent  = true,
      }
    )
  end

  api.nvim_buf_set_keymap(
    bufnr,
    'n',
    require('NuiTerm').eventController.ntConfigHandler.keymaps.rename_term,
    [[<cmd>lua require('NuiTerm').eventController:Rename()<CR>]],
    {
      noremap = true,
      silent  = true,
    }
  )
end

---@param bufnr number
M.RemoveTermKeymaps = function(bufnr)
  -- api.nvim_del_autocmd(self.autocmdid) -- When moving outside of NuiTerm Bufnr
  api.nvim_buf_del_keymap(bufnr, 't', '<Esc>')
  api.nvim_buf_del_keymap(bufnr, 'n', 'i')
  api.nvim_buf_del_keymap(bufnr, 'n', '<Esc>')
end

return M
