local ngx_re_split = require "ngx.re".split

local influxdb_query = require "influxdb".query

local table_concat = table.concat


local _M = {}
_M.name = "example_model"
_M._VERSION = "0.1"


return _M
