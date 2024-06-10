--> NuiTerm/setup.lua
--
local M = {}

M.NSID = vim.api.nvim_create_namespace("NuiTerm")
M.winConfig = {
}
M.keyMaps = {
  nuiterm_toggle = "<leader>tt",
  next_term = "<C-l>",
  prev_term = "<C-h>",
}

function M.setup(opts)
  local win_config   = opts.win_config or {}
  local user_keymaps = opts.user_keymaps or {}

  M.keyMaps   = vim.tbl_extend('force', M.keyMaps, user_keymaps)
  M.winConfig = vim.tbl_extend('force', M.winConfig, win_config)
end

return M
