--> NuiTerm/utils.lua
--

local M = {}
local log = require("NuiTerm.Debug").LOG_FN("config", {
  deactivated = false
})

---@alias close_win_if_valid fun(winid: number, force: boolean): unknown

---@param winid number
---@param force boolean
M.close_win_if_valid = function(winid, force)
  log("winid: "..winid, "close_win_if_valid")
  if not vim.api.nvim_win_is_valid(winid) then
    error(string.format("Provided winid( %d ) is not valid", winid), 1)
  end
  vim.api.nvim_win_close(winid, force)
end
---@param bufnr number
---@param force boolean
M.delete_bufnr_if_valid = function(bufnr, force)
  log("bufnr: "..bufnr, "delete_bufnr_if_valid")
  if not vim.api.nvim_buf_is_valid(bufnr) then
    error(string.format("Provided bufnr( %d ) is not valud", bufnr), 1)
  end
  vim.api.nvim_buf_delete(bufnr, { force = force })
end

M.OriginalWidthSetting = nil
M.GetTermSize = function()
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

M.GetMousePos = function()
  return pcall(vim.fn.getmousepos)
end

M.MergeConfigs = function(defaults, overrides)
  if not overrides then return defaults end

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
    overrides[k] = M.MergeConfigs(v, overrides[k])
    ::continue::
  end
  return overrides
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


---@param tWidth number
---@param divisor number
function CalculateCoordinates(tWidth, divisor)
  local termWidth = vim.o.columns
  local winCol   = 0
  local tabCol   = 0 -- For Alignment: TabBar needs to be more specifc because TermWidow's border takes up +1 row/col around the window
  tWidth = math.floor(termWidth * (divisor))
  if termWidth % 2 == 1 and tWidth % 2 == 0 then
    tWidth = tWidth - 1
    tabCol = -2
  elseif termWidth % 2 == 0 and tWidth % 2 == 1 then
    tWidth = tWidth + 1
    tabCol = 2
  end
  winCol = math.ceil(termWidth/2) - math.floor(tWidth/2)
  tabCol = tabCol + winCol
  return tWidth, winCol, tabCol
end

--- Returns Window Width, Width x position, TabBar X position 
---@param width number|string
M.WidthPCT = function (width)
  M.OriginalWidthSetting = width
  local termWidth = vim.o.columns

  -- No point in having a termianl window smaller then 144
  if termWidth < 144 then return termWidth, 0, 0 end

  if type(width) == "number" then
    -- return width, 0, 0
    local divisor = math.floor(width / vim.o.columns)
    if divisor > 1.0 then
      return termWidth, 0, 0
    end
    return CalculateCoordinates(width, divisor)
  end

  if type(width) == "string" then
    local num, den = string.match(width, "^(%d+)/(%d+)$")
    if not num or not den then
      -- return termWidth, winCol, tabCol
      return termWidth, 0, 0
    end

    num, den = tonumber(num), tonumber(den)
    if num > den then
      return termWidth, 0, 0
    end

    return CalculateCoordinates(termWidth, num/den)
  end
  print("Unknown type for width: "..type(width))
  return termWidth, 0, 0
end

--TODO: Redo how you handle NuiTerm's Resizing/repositioing during Terminal resize.
-- After you intergrated chaning NuiTerms width with auto centering. You noticed that
-- the old way of resizing now messes with this.
--
-- You need to globally store the users preference for 'width' i.e., if it's a percentage
-- then we'll need that here. 
-- Next, during MainWindow.OnResize. You'll need to handle MainWindow Resiizing and TabBar
-- resize
M.ResizeAndPosition = function()
  return M.WidthPCT(M.OriginalWidthSetting)
end

return M
