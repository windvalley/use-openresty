-- 官方模块
local ngx = require "ngx"

-- 自定义库模块
local http = require "http"

-- 应用模块
local config = require "config"
local response = require "response"

-- 将函数缓存下来
local ngx_encode_base64 = ngx.encode_base64


local _M = {}
_M._VERSION = "0.1"
_M.name = "orientdb"


local host = config.orientdb_conf["host"]
local port = config.orientdb_conf["port"]
local db = config.orientdb_conf["db"]
local user = config.orientdb_conf["user"]
local password = config.orientdb_conf["password"]
local timeout = config.orientdb_conf["timeout"]
local keepalive_timeout = config.orientdb_conf["keepalive_timeout"]
local keepalive_pool = config.orientdb_conf["keepalive_pool"]


-- 查询orientdb的http api前缀
local orientdb_base_api = "http://" .. host .. ":" .. port
                          .. "/query/" .. db .. "/sql/"

local headers = {}
-- http basic 认证
if user ~= "" and password ~= "" then
    local auth_str = user .. ":" .. password
    local basic_auth = ngx_encode_base64(auth_str)
    headers["Authorization"] = "Basic " .. basic_auth
end


-- 查询orientdb, 返回result table
local n = 1  -- error.log中对请求orientdb计数
_M.query = function(sql)
    print(n .. "***************************: " .. sql)
    n = n + 1

    local query_api = orientdb_base_api .. sql

    local res, err = http.request(query_api,
                                  "GET",
                                  timeout,
                                  keepalive_timeout,
                                  keepalive_pool,
                                  headers)

    if not res then
        return response.db_err(err, sql)
        --return {}  -- 忽略后端错误, 从而使业务api不会报错.
    end

    local data = res.result

    return data
end


return _M
