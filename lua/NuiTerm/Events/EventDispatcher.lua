--> NuiTerm/Event.lua
--

-- Event System should be the central Point of command. You'll need to reroute all of the 
-- Keymaps to/from NTEvent. At the moment, the psudo-event system NuiTerm has is completely
-- linear and horizontal. We need to change that and make NTEvent the centeral point. Where
-- We connect all of the UI components TO NTEvent instead of connecting everything to MainWindow.
-- Doing it this way will open the doors for more Features and more customizaiton.
local log = require("NuiTerm.Debug").LOG_FN("NTEvent", {
  deavative = false
})

---@enum nuiterm.events
local EVENTS = {
  show_nuiterm   =  1,
  hide_nuiterm   =  2,
  rename_nuiterm =  3,
  delete_nuiterm =  4,
  goto_terminal  =  5,
  new_terminal   =  6,
  next_terminal  =  7,
  prev_terminal  =  8,

  term_sizing    =  9,
  term_ui_update = 10,
}

---@alias DispatchCallback function<string|number|table|boolean>
---@alias Listeners table<number, DispatchCallback>

---@class NTEventDispatcher
---@field listeners Listeners
local NTEventDispatcher = {}

function NTEventDispatcher:new()
  local obj = {
    listeners = {}
  }
  setmetatable(obj, self)
  return obj
end

--- Subscribes a NuiTerm Component into NuiTerms Global EventSystem
--- Dispatcher.
---@param eventType nuiterm.events
---@param listener  any
function NTEventDispatcher:subscribe(eventType, listener)
  if not self.subscribe[eventType] then
    self.subscribe[eventType] = {}
  end
  table.insert(self.listeners[eventType], listener)
end

---@param eventType nuiterm.events
---@param listener  any
function NTEventDispatcher:unsubscribe(eventType, listener)
  if not self.listeners[eventType] then return end
  for i, l in ipairs(self.listeners[eventType]) do
    if l == listener then
      table.remove(self.listeners[eventType], i)
      break
    end
  end
end

---@param eventType nuiterm.events
---@param data      any
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
