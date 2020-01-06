-- example_api的前端展示, 仅用于测试接口数据的展示, 可忽略这个文件

local ngx = require "ngx"

local loadfile_to_ram = require "utils".loadfile_to_ram

local waf = require "waf"
local response = require "response"

local ngx_var = ngx.var
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_re_sub = ngx.re.sub


local _M = {}

_M.name = "example_api2"
_M._VERSION = "0.1"


_M.access = function()
    waf.deny_ip_access()
end


_M.content = function()

end


return _M
