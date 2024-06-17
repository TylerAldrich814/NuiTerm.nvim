--> NuiTerm/Config/defaults.lua
--
local Defaults = {}

Defaults.winConfig = function()
  return {
    width    = vim.o.columns,
    height   = 20,
    position = "bottom",
    style    = "minimal",
    border   = "rounded"
  }
end

---@param col   number
---@param row   number
Defaults.tabBarConfig = function(row, col)
  return {
    relative  = "win",
    width     = 2, -- no border padding
    height    = 1,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "none",
    focusable = false,
  }
end

----@alias tabConfig {relative:string, win:number, width:number, height:number, style:string, border:string, row:number, col:number}
---@param col   number
---@param row   number
---@param width number
Defaults.tabConfig = function(col, row, width)
  return {
    col    = col,
    row    = row,
    width  = 25,
    height = 1,
    nuiWidth = width
  }
end

---@alias RenameLabelConfig {relative:string, win:number, width:number, height:number, style:string, border:string, row:number, col:number}
Defaults.RenameLabelConfig = function()
  return {
    relative = "win",
    win      = nil,
    width    = 10,
    height   = 1,
    style    = "minimal",
    border   = "rounded",
    row      = nil,
    col      = nil,
  }
end

---@alias RenameInputConfig {relative:string, win:number, width:number, height:number, style:string, border:string, row:number, col:number}
Defaults.RenameInputConfig = function()
  return {
    relative = "win",
    win      = nil,
    width    = 35,
    height   = 1,
    style    = "minimal",
    border   = "rounded",
    row      = nil,
    col      = nil,
  }
end

Defaults.keymaps = function()
  return  {
    change_mode    = "<Esc>",
    rename_term    = "<leader>tr",
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
end

return Defaults
