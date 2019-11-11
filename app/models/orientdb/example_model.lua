local ngx = require "ngx"
local table_nkeys = require "table.nkeys"

local orientdb_query = require "models.orientdb".query
local response = require "response"

local table_insert = table.insert


local _M = {}
_M.name = "example_model"
_M._VERSION = "0.1"


return _M
