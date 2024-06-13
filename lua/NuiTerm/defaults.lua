--> NuiTerm/defaults.lua
--
local M = {}

M.winConfig = function()
  return {
    width    = vim.o.columns,
    height   = 20,
    position = "bottom",
    style    = "minimal",
    border   = "rounded"
  }
end
M.keyMaps = {
  change_mode    = "<Esc>",
  nuiterm_toggle = "<leader>tt",
  new_term       = "<leader>tn",
  next_term      = "<leader>tk",
  prev_term      = "<leader>tj",
  close_term     = "<leader>tx",
  term_resize    = {
    expand = { cmd = "<C-p>", amt = 1 },
    shrink = { cmd = "<C-o>", amt = -1 }
  },
}


return M
