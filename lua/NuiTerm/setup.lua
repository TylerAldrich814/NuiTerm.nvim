--> NuiTerm/setup.lua
--

local M = {}

M.NSID = vim.api.nvim_create_namespace("NuiTerm")

--TODO: You need to figure out why you're getting an error if you don't include 
--      ALL of the keyMaps within lazy setup of NuiTerm
M.winConfig = {
  width    = vim.o.columns,
  height   = 20,
  position = "bottom", -- | "top"
  style    = "minimal",
  border   = "rounded"
}
M.keyMaps = {
  nuiterm_toggle = "<leader>tt",
  new_term       = "<leader>tn",
  next_term      = "<leader>tl",
  prev_term      = "<leader>tk",
}

function M.setup(opts)
  local user_keymaps = opts.user_keymaps or {}
  local win_config   = opts.win_config or {}

  M.keyMaps = vim.tbl_extend('force', M.keyMaps, user_keymaps)
  M.winConfig = vim.tbl_extend('force', M.winConfig, win_config)
end

return M
