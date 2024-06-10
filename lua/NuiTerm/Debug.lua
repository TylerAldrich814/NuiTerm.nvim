--> LuaTerm/Debug.lua
--

MSG_ID = 0
local debug_active = true
local function Debug(msg)
  if debug_active then
    print(" - [" .. MSG_ID .. "] :: " .. msg)
    MSG_ID = MSG_ID + 1
  end
end

return {
  Debug = Debug,
}
