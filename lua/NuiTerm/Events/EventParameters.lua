--> NuiTerm/EventParameters.lua
--
local EVENTS = require("NuiTerm.Events.EventDispatcher").EVENTS

---@class EventParamters
local EventParamters = { }

function EventParamters:new(dispatcher)
  local obj = setmetatable({
    dispatcher   = dispatcher,
    active       = false,
    stateChange  = false,
    currentWinid = nil,
    currentBufnr = nil,
    autocmd_ids  = {},
  }, {__index = self})

  return obj
end

function EventParamters:PushSubscriptions()
  self.dispatcher:subscribe(EVENTS.update_current_winid, function(arg)
    self.currentWinid = arg
  end)
  self.dispatcher:subscribe(EVENTS.update_current_bufnr, function(arg)
    self.currentBufnr = arg
  end)
  self.dispatcher:subscribe(EVENTS.get_current_winid, function(_)
    return self.currentWinid
  end)
  self.dispatcher:subscribe(EVENTS.get_current_bufnr, function(_)
    return self.currentBufnr
  end)
end

---@param name string
---@param id   number
function EventParamters:PushAutoCmdID(name, id)
  self.autocmd_ids[name] = id
end

return EventParamters
