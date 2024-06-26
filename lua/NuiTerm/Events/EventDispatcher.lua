--> NuiTerm/Event.lua
--

-- Event System should be the central Point of command. You'll need to reroute all of the 
-- Keymaps to/from NTEvent. At the moment, the psudo-event system NuiTerm has is completely
-- linear and horizontal. We need to change that and make NTEvent the centeral point. Where
-- We connect all of the UI components TO NTEvent instead of connecting everything to MainWindow.
-- Doing it this way will open the doors for more Features and more customizaiton.
local log = require("NuiTerm.Debug").LOG_FN("NTEvent", {
  deavatived = true
})

---@enum nuiterm.events
local EVENTS = {
  -- toggle_nuiterm =  0,
  show_nuiterm   =  1,
  hide_nuiterm   =  2,
  exit_nuiterm  =  3,

  rename_setup   =  4,
  rename_start   =  5,
  rename_finish  =  6,

  delete_nuiterm =  7,
  goto_terminal  =  8,
  new_terminal   =  9,
  next_terminal  = 10,
  prev_terminal  = 11,

  user_resizing  = 12,
  term_resizing  = 13,
  update_ui      = 14,

  update_tab_bar = 15,

  update_current_winid = 16,
  update_current_bufnr = 17,
  get_current_winid    = 18,
  get_current_bufnr    = 19,


  db_initialize    = 20,
  db_configuration = 21,
  db_showInstances = 22,
}
---@param value number
local function db_event_str(value)
  for k, v in pairs(EVENTS) do
    if v == value then
      return k
    end
  end
  return nil
end

---@class NTEventDispatcher
local NTEventDispatcher = {}

function NTEventDispatcher:new()
  local obj = setmetatable({
    listeners = {},
  }, {__index = self})

  return obj
end

--- Subscribes a NuiTerm Component into NuiTerms Global EventSystem
--- Dispatcher.
function NTEventDispatcher:subscribe(eventType, listener)
  if not self.listeners[eventType] then
    self.listeners[eventType] = {}
  end
  table.insert(self.listeners[eventType], listener)
end

function NTEventDispatcher:unsubscribe(eventType, listener)
  if not self.listeners[eventType] then return end
  for i, l in ipairs(self.listeners[eventType]) do
    if l == listener then
      table.remove(self.listeners[eventType], i)
      break
    end
  end
end

function NTEventDispatcher:emit(eventType, data)
  if not self.listeners[eventType] then return end
  for _, listener in ipairs(self.listeners[eventType]) do
    listener(data)
  end
end

return {
  NTEventDispatcher = NTEventDispatcher,
  EVENTS = EVENTS,
}
