-- 官方模块部分
local ngx = require "ngx"
local ngx_re_split = require "ngx.re".split
local table_nkeys = require "table.nkeys"

-- 应用模块部分
local example_model = require "models.orientdb.example_model"
local response = require "response"
local waf = require "waf"
local cache = require "cache"

-- 对官方、第三方或自定义模块的api进行缓存
local ngx_var = ngx.var
local ipairs = ipairs
local tonumber = tonumber
local common_cache = cache.get_common_cache()


local _M = {}

_M.name = "example_api"
_M._VERSION = "0.1"


-- 在OpenResty的access阶段, 执行该函数
_M.access = function()
    waf.deny_ip_access()
    waf.method_allow{"GET", "POST"}
end


-- 在OpenResty的content阶段, 执行该函数.
-- 在这里写业务API的主要逻辑部分.
_M.content = function()
    --[==[
    local domain = ngx_var.arg_domain
    if not domain then
        response.arg_err()
    end

    -- callback function
    local get_resp_data = function()
        -- return data, nil, 300  -- 数据, 错误信息, 自定义缓存时间
        return data
    end

    -- 如果update参数值为"1", 则主动更新缓存
    local update = ngx_var.arg_update
    if update == "1" then
        response.update_say(fqdn, get_resp_data)
        return
    end

    response.cache_say(fqdn, get_resp_data)
    ]==]
end


return _M
