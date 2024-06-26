--- NuiTerm/sql/init.lua
--
-- local sqlite_db = require("sqlite.db")
-- local sqlite_tbl = require("sqlite.tbl")
local sqlite     = require("sqlite")
local sqlite_db  = require("sqlite.db")
local tbl = require("sqlite").tbl
local log = require("NuiTerm.Debug").LOG_FN({
  deactivate = false,
})

local julianday, strftime = sqlite.lib.julianday, sqlite.lib.strftime

---@class NuitermSessions: sqplite_tbl

---@class NuitermDatabase: sqplite_db
---@field enties     NuitermSessions
---@field collection sqlite_tbl
---@field ts         sqplite_tbl

---@class NuiTermCollection
---@field collection string: collection title

---@class NTSession
---@field id number: unique id
---@field project string: The Project this session belongs to
---@field doc number: date of creation
---@field collection string: foreign key referencing NuiTermCollection.title

---@class NuiTermTimeStamp
---@field id number: unique id
---@field timestamp number
---@field entry number: foreign key referencing NTSession

local function root()
  local root = debug.getinfo(1, "S").source:sub(2)
  return root:match("(.*/)")
end

-- ---@class DB @main sqplite.lua object
-- local DB = sqlite {
--   uri = root(),
-- }

---@type NuitermSessions
local NuitermSessions tbl("NuitermSessions", {
  id    = true,
  link  = { "text",   required = true },
  title = "text",
  since = { "date",   default=strftime("%s", "now") },
  count = { "number", default=0 },
  type  = { "text",   required=true },
  collection = {
    type = "text",
    reference = "collection.title",
    on_update = "cascade",
    on_delete = "null"
  }
})

---@type NuitermDatabase
local NuiTermDatabase = sqlite { }

---@param config table
---@return NuitermDatabase
local InitializeDB = function (config)
  return NuiTermDatabase{
    uri     = config.NuiTermDatabase or root(),
    entries = NuitermSessions,
    collection = {
      title = {
        "text",
        required = true,
        unique   = true,
        primary  = true,
      },
    },
    ts = {
      _name     = "timestamp",
      id        = true,
      timestamp = { "real", default = julianday("now")},
      entry     = {
        type = "integer",
        reference = "entries.id",
        on_delete = "cascase"
      }
    },
    opts = {},
  }
end

local function OnInitiailized(nuiTermDatabase)
  local collection, ts = nuiTermDatabase.collection, nuiTermDatabase.ts
  if not collection then
    error("NuiTermDatabase.collection is nil", 3)
  end
  if not ts then
    error("NuiTermDatabase.ts is nil", 3)
  end

  ---@param id number
  function ts:insert(id)
    ts:__insert{ entry=id }
  end

  ---@param id number
  ---@return NuiTermTim
  function ts:get(id)

  end

end


return {
  InitializeDB = InitializeDB,
  OnInitiailized = OnInitiailized,
  NuiTermDB = NuiTermDatabase,
}
