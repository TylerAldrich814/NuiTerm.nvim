--> NuiTerm/Event.lua
--
local Debug             = require("NuiTerm.Debug")
local NTEventDispatcher = require("NuiTerm.Events.EventDispatcher").NTEventDispatcher
local EventParameters   = require("NuiTerm.Events.EventParameters")
local EVENTS            = require("NuiTerm.Events.EventDispatcher").EVENTS
local NuiTermWindow     = require("NuiTerm.UI.MainWindow")
local TabBar            = require("NuiTerm.UI.TabBar.Bar")
local NTConfigHandler   = require("NuiTerm.Config.Handler")

local Utils             = require("NuiTerm.utils")
local log               = require("NuiTerm.Debug").LOG_FN("NTEventController", {
  deactivate = true,
})

---@class NTEventController
local NTEventController = {}

---@param opts table
function NTEventController:new(opts)
  local dispatcher    = NTEventDispatcher:new()
  local ntConfig      = NTConfigHandler:new(opts)
  local nuiTermWindow = NuiTermWindow:new(dispatcher, ntConfig.window, ntConfig.shell)
  local nuiTermTabBar = TabBar:new(dispatcher, ntConfig.tabBar, ntConfig.tab)
  nuiTermWindow:PushSubscriptions()
  nuiTermTabBar:PushSubscriptions()

  local obj = setmetatable({
    dispatcher      = dispatcher,
    nuiTermWindow   = nuiTermWindow,
    nuiTermTabBar   = nuiTermTabBar,
    ntConfigHandler = ntConfig,
    paramters       = EventParameters:new(dispatcher),
  }, { __index = self })


  return obj
end

function NTEventController:PushSubscriptions()
  self.dispatcher:subscribe(EVENTS.exit_nuiterm, function(_)
    self.paramters.active = false
  end)
end

function NTEventController:GlobalAutoCmds()
  self.paramters:PushAutoCmdID(
    "TermResize",
    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        local width, winCol, tabCol = Utils.ResizeAndPosition()
        self.dispatcher:emit(EVENTS.term_resizing, {
          width  = width,
          winCol = winCol,
          tabCol = tabCol,
        })
      end
    })
  )
end

function NTEventController:SetupUserCmds()
  for _, cmd in pairs({
    {
      cmd  = "Rename",
      fn   = function() self:Rename() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "ToggleWindow",
      fn   = function() self:Toggle() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "ShowWindow",
      fn   = function() self:Show() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "HideWindow",
      fn   = function() self:Hide() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "Resize",
      fn   = function(opts) self:Resize(opts.args) end,
      opts = { nargs = 1 },
    },
    {
      cmd  = "NewTerm",
      fn   = function() self:NewTerm() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "DelTerm",
      fn   = function(opts)
        local term_id = tonumber(opts.args)
        if term_id then
          self:DelTerm(term_id)
        end
      end,
      opts = { nargs = 1 }
    },
    {
      cmd  = "DeleteCurrentTerm",
      fn   = function() self:DelTerm(nil) end,
      opts = { nargs = 1 }
    },
    {
      cmd  = "ToTerm",
      fn   = function(opts)
        local term_id = tonumber(opts.args)
        self:GoToTerm(term_id)
      end,
      opts = { nargs = 1 }
    },
    {
      cmd  = "NextTerm",
      fn   = function() self:NextTerm() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "PrevTerm",
      fn   = function() self:PrevTerm() end,
      opts = { nargs = 0 }
    },
    -- Keymaps for while in developemnt
    {
      cmd  = "DebugShow",
      fn   = function() Debug.create_or_get_debug_window() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "DebugHide",
      fn   = function() Debug.hide_debug_window() end,
      opts = { nargs = 0 }
    },
    {
      cmd  = "DebugToggle",
      fn   = function() Debug.ToggleDebug() end,
      opts = { nargs = 0 }
    },

  }) do
    vim.api.nvim_create_user_command("NuiTerm" .. cmd.cmd, cmd.fn, cmd.opts)
  end

  log(string.format("keymaps.toggle:  %s", self.ntConfigHandler.keymaps.nuiterm_toggle), "SetupUserCmds")
  log(string.format("keymaps.newTerm: %s", self.ntConfigHandler.keymaps.new_term), "SetupUserCmds")
  vim.keymap.set(
    'n',
    self.ntConfigHandler.keymaps.nuiterm_toggle,
    function()
      -- M.MainWindow:Toggle()
      self:Toggle()
    end,
    {
      noremap = true,
      silent  = true,
    }
  )
  vim.keymap.set(
    'n',
    self.ntConfigHandler.keymaps.new_term,
    function()
      -- M.MainWindow:NewTerm()
      self:NewTerm()
    end,
    {
      noremap = true,
      silent  = true,
    }
  )
end

--- UserCommands
function NTEventController:Show()
  self.dispatcher:emit(EVENTS.show_nuiterm, nil)
  self.paramters.active = true
end

function NTEventController:Hide()
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.hide_nuiterm, nil)
  self.paramters.active = false
end

function NTEventController:Toggle()
  if not self.paramters.active then
    self:Show()
  else
    self:Hide()
  end
end

function NTEventController:Rename()
  log("Emmiting Rename", "Rename")
  --TODO: Extract Renaming feature into it's own file. Then emit rename event
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.rename_setup, nil)
end

function NTEventController:Resize(arg)
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.user_resizing, arg)
end

function NTEventController:Expand()
  if not self.paramters.active then return end
  -- self.NuiTermWindow:Resize(self)
  error("You need to setup Keymaps controller")
end

function NTEventController:NewTerm()
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.new_terminal, nil)
end

function NTEventController:DelTerm(arg)
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.delete_nuiterm, arg)
end

function NTEventController:GoToTerm(arg)
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.goto_terminal, arg)
end

function NTEventController:NextTerm()
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.next_terminal, nil)
end

function NTEventController:PrevTerm()
  if not self.paramters.active then return end
  self.dispatcher:emit(EVENTS.prev_terminal, nil)
end

return NTEventController
