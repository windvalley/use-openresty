-- Used to temporarily test openresty api functions

local ngx = require "ngx"

local loadfile_to_ram = require "utils".loadfile_to_ram

local waf = require "waf"
local response = require "response"

local ngx_var = ngx.var
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_re_sub = ngx.re.sub


local _M = {}

_M.name = "test"
_M._VERSION = "0.1"


_M.access = function()
end


_M.content = function()
    ngx.say(ngx_var.uri)
end


return _M
