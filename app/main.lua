-- 整个大应用的入口程序


-- 官方模块部分
local ngx = require "ngx"

-- 应用模块部分
local router = require "router".url_path
local response = require "response"

-- 将模块的api进行缓存
local ngx_var = ngx.var
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_re_find = ngx.re.find
local pairs = pairs


local _M = {}

_M.name = "main"
_M._VERSION = "0.1"


setmetatable(_M, { __index = function(self, handler_name)
    local func = function()
        local request_url_path = ngx_var.uri
        -- 路由匹配、webapi程序执行
        for router_path, api in pairs(router) do
            local router_path_re = [[^]] .. router_path .. [[$]]
            local match, _ = ngx_re_find(request_url_path, router_path_re, "jo")
            if match then
                local f = api[handler_name]
                local err = f and f()
                if err then
                    ngx_log(ngx_ERR, api, " error: ", err)
                end
                return  -- 从这里终止func函数的执行
            end
        end

        -- 如果用户访问了不存在的url path, 则提示错误.
        response.url_err(request_url_path)
    end

    _M[handler_name] = func

    return func
end
})


return _M
