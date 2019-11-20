local ngx = require "ngx"
local cjson = require "cjson"
local resty_shell = require "resty.shell"
local table_nkeys = require "table.nkeys"
local ngx_re_split = require "ngx.re".split

local redis = require "models.redis"
local config = require "config"
local utils = require "utils"
local waf = require "waf"

local table_top_slice = utils.table_top_slice
local item_if_in_table = utils.item_if_in_table
local ngx_var = ngx.var
local ngx_req = ngx.req
local ngx_redirect = ngx.redirect
local cjson_encode = cjson.encode
local cjson_decode = cjson.decode
local string_sub = string.sub
local tonumber = tonumber


local _M = {}

_M.name = "example_api_get"
_M._VERSION = "0.1"


_M.access = function()
    waf.deny_ip_access()
end


_M.content = function()

end


return _M
