--> NuiTerm/setup.lua
--

local M = {}

M.NSID = vim.api.nvim_create_namespace("NuiTerm")

M.winConfig = {
  width    = vim.o.columns,
  height   = 20,
  position = "bottom", -- | "top"
  style    = "minimal",
  border   = "rounded"
}
M.keyMaps = {
  nuiterm_toggle = "<leader>tt",
  next_term = "<C-l>",
  prev_term = "<C-h>",
}

function M.setup(opts)
  local user_keymaps = opts.user_keymaps or {}
  local win_config   = opts.win_config or {}

  M.keyMaps = vim.tbl_extend('force', M.keyMaps, user_keymaps)
  M.winConfig = vim.tbl_extend('force', M.winConfig, win_config)
end

return M
