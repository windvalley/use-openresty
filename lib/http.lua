local ngx = require "ngx"
local cjson_safe = require "cjson.safe"

-- https://github.com/ledgetech/lua-resty-http
local http = require "resty.http"

local cjson_safe_decode = cjson_safe.decode
local ngx_re_gsub = ngx.re.gsub
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR


local _M = {}
_M._VERSION = "0.1"
_M.name = "http"


_M.request = function(url,
                      method,
                      timeout,
                      keepalive_timeout,
                      keepalive_pool,
                      headers)

    -- 将url中的空格编码为%20, 否则后端不识别.
    local url_encode, _, _ = ngx_re_gsub(url, [[ ]], "%20", "i")

    local httpc = http.new()

    httpc:set_timeout(timeout or 2000)

    local res, err = httpc:request_uri(url_encode, {
        method = method or "GET",
        headers = headers or {},
        keepalive_timeout = keepalive_timeout or 10000,
        keepalive_pool = keepalive_pool or 50,
    })

    if not res then
        ngx_log(ngx_ERR, "request ", url, " error: ", err)
    end

    -- cjson_safe_decode遇到错误不退出.
    local body_table = cjson_safe_decode(res.body)

    return body_table, err
end


return _M
