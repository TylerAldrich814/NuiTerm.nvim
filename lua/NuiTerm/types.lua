---@meta _

---@class EventParamters
---@field dispatcher   NTEventDispatcher
---@field active       boolean
---@field stateChange  boolean
---@field currentWinid number
---@field currentBufnr number
---@field autocmd_ids  table<string, number>
---@field PushSubscriptions fun(self: EventParamters): nil
---@field PushAutoCmdID     fun(self: EventParamters, name: string, id: number): nil


---@alias DispatchCallback function<string|number|table|boolean>
---@alias Listeners table<nuiterm.events, DispatchCallback>
---@alias EmitData number|string|table|boolean|nil

---@class NTEventDispatcher
---@field listeners   Listeners
---@field subscribe   fun(self: NTEventDispatcher, eventType: nuiterm.events, listener: function): nil
---@field unsubscribe fun(self: NTEventDispatcher, eventType: nuiterm.events, listener: function): nil
---@field emit        fun(self: NTEventDispatcher, eventType: nuiterm.events, data: EmitData): nil

---@class NTEventController
---@field dispatcher      NTEventDispatcher
---@field nuiTermWindow   MainWindow
---@field nuiTermTabBar   TabBar
---@field ntConfigHandler NTConfigHandler
---@field paramters       EventParamters
---@field GlobalAutoCmds  fun(self: NTEventController): nil
---@field SetupUserCmds   fun(self: NTEventController): nil
---@field Rename          fun(self: NTEventController): nil
---@field Toggle          fun(self: NTEventController): nil
---@field Show            fun(self: NTEventController): nil
---@field Hide            fun(self: NTEventController): nil
---@field Resize          fun(self: NTEventController, arg: EmitData): nil
---@field Expand          fun(self: NTEventController): nil
---@field NewTerm         fun(self: NTEventController): nil
---@field DelTerm         fun(self: NTEventController, arg: EmitData): nil
---@field GoToTerm        fun(self: NTEventController, arg: EmitData): nil
---@field NextTerm        fun(self: NTEventController): nil
---@field PrevTerm        fun(self: NTEventController): nil


---@class NTConfigHandler
---@field opts    table
---@field window  table
---@field tabBar  table
---@field tab     table
---@field shell   table
---@field keymaps table

---@class MainWindow
---@field dispatcher    NTEventDispatcher
---@field mainNsid      integer|nil
---@field termNsid      integer|nil
---@field mainWinid     integer|nil
---@field mainWinBufnr  integer|nil
---@field curTermWinid  integer|nil
---@field initialized   boolean
---@field showing       boolean
---@field totalTerms    number
---@field currentTermID number|nil
---@field termWindows   TermWindow[]
---@field winConfig     table
---@field shellConfig   table
---@field resizeCmdID   number|nil
----@field New               fun(dispatcher: NTEventDispatcher, winConfig: table): MainWindow
---@field PushSubscriptions fun(self: MainWindow): nil
---@field PushIds           fun(self: MainWindow): nil
---@field CreateNewTerm     fun(self: MainWindow): number
---@field ShowTermianl      fun(self: MainWindow, id: number): nil
---@field NewTerminal       fun(self: MainWindow): nil
---@field NewTerm           fun(self: MainWindow): nil
---@field Show              fun(self: MainWindow): nil
---@field Hide              fun(self: MainWindow): nil
---@field UpdateUI          fun(self: MainWindow): nil
---@field Toggle            fun(self: MainWindow): nil
---@field DeleteTerm        fun(self: MainWindow, term_id: number): nil
---@field ToTerm            fun(self: MainWindow, term_id: number): nil
---@field NextTerm          fun(self: MainWindow): nil
---@field PrevTerm          fun(self: MainWindow): nil
---@field TermMode          fun(self: MainWindow): nil
---@field NormMode          fun(self: MainWindow): nil
---@field GetTermNames      fun(self: MainWindow): table
---@field UpdateBarBar      fun(self: MainWindow): table
---@field Resize            fun(self: MainWindow, arg: EmitData): nil
---@field OnTermResize      fun(self: MainWindow, arg: EmitData): nil
---@field RenameStart       fun(self: MainWindow): nil
---@field RenameEnd         fun(self: MainWindow, newName: string): nil

---@class TermWindow
---@field bufnr       number|nil
---@field winid       number|nil
---@field termid      number|nil
---@field name        string
---@field autocmdid   number|nil
---@field config      table
---@field onHide      function|nil
---@field showing     boolean
---@field spawned     boolean
---@field initialized boolean
----@field Init         fun(termid: number, config: table): TermWindow
---@field IsBufValid   fun(self: TermWindow): boolean
---@field OnHoverOver  fun(self: TermWindow, curent: number): nil
---@field RecreateBuf  fun(self: TermWindow): nil
---@field SpawnShell   fun(self: TermWindow): nil
---@field Show         fun(self: TermWindow): number
---@field Hide         fun(self: TermWindow): nil
---@field Delete       fun(self: TermWindow): nil
---@field UpdateConfig fun(self: TermWindow, config: table): nil


---@class TabBar
---@field dispatcher    NTEventDispatcher
---@field nuiTermRename NuiTermRename
---@field winid         number|nil
---@field bufnr         number|nil
---@field tabs          Tab[]
---@field config        table
---@field tabConfig     table
---@field seperator     string
---@field onClick       function
---@field PushSubscriptions fun(self: TabBar): nil
---@field SetTabs           fun(self: TabBar, args: EmitData): nil
---@field Hide              fun(self: TabBar): nil
---@field onHover           fun(self: TabBar, position: number): nil
---@field setupOnHover      fun(self: TabBar): nil
---@field OnTermResize      fun(self: TabBar, args: EmitData): nil
---@field UpdateRow         fun(self: TabBar, row: number, abs: boolean): nil
---@field UpdateCol         fun(self: TabBar, col: number, abs: boolean): nil
---@field UpdateWidth       fun(self: TabBar, width: number): nil
----@field RenameOnEvneterCb fun(self: TabBar, nenameBufnr: ): nil
---@field n                 fun(self: TabBar): nil

