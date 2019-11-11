local ngx = require "ngx"
local limit_req = require "resty.limit.req"

local config = require "config"
local response = require "response"

local ngx_var = ngx.var
local ngx_req = ngx.req
local ngx_md5 = ngx.md5
local ngx_sleep = ngx.sleep
local ngx_exit = ngx.exit
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ip_whitelist = config.ip_whitelist


local _M = {}
_M._VERSION = "0.1"
_M.name = "waf"


-- 白名单
_M.deny_ip_access = function()
    if #ip_whitelist == 0 then
        return
    end

    local client_ip = ngx_var.remote_addr
    for _, v in ipairs(ip_whitelist) do
        if client_ip == v then
            return
        end
    end

    return ngx.exit(403)
end


-- 请求方法过滤
-- arg method_table is like {"GET", "POST",}
_M.method_allow = function(method_table)
    local method = ngx_req.get_method()
    for _, item in ipairs(method_table) do
        if method == item then
            return
        end
    end

    response.method_err(method, method_table)
end


-- 鉴权
local auth_key = config.authenticate["auth_key"] or ""

_M.authenticate = function(uri)
    local client_token = ngx_var.arg_token
    if not client_token then
        response.auth_err()
    end

    local server_token = ngx_md5("token=" .. auth_key .. uri)
    if client_token ~= server_token then
        response.auth_err()
    end
end


-- 用户请求并发限制
local limit_flag = config.request_limit["limit"] or false
local limit_number = config.request_limit["limit_number_per_second"] or 1000
local burst_number = config.request_limit["burst_number"] or 100

_M.request_limit = function()
    if not limit_flag then
        return
    end

    local lim, err, delay, key
    lim, err = limit_req.new("my_limit_req_store", limit_number, burst_number)
    if not lim then
        ngx_log(ngx_ERR,
                "failed to instantiate a resty.limit.req object: ",
                err)
        return ngx_exit(500)
    end

    key = ngx_var.binary_remote_addr
    delay, err = lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx_exit(503)
        end
        ngx_log(ngx_ERR, "failed to limit req: ", err)
        return ngx_exit(500)
    end

    if delay >= 0.001 then
        ngx_sleep(delay)
    end
end


return _M
