local ngx = require "ngx"

local http = require "http"  -- 自定义库模块

local config = require "config"
local response = require "response"

local ngx_encode_base64 = ngx.encode_base64


local _M = {}
_M._VERSION = "0.1"
_M.name = "influxdb"


local host = config.influxdb_conf["host"] or "127.0.0.1"
local port = config.influxdb_conf["port"] or 8086
local db = config.influxdb_conf["db"]
local user = config.influxdb_conf["user"] or ""
local password = config.influxdb_conf["password"] or ""
local timeout = config.influxdb_conf["timeout"] or 2000
local keepalive_timeout = config.influxdb_conf["keepalive_timeout"] or 10000
local keepalive_pool = config.influxdb_conf["keepalive_pool"] or 50


-- 查询influxdb的http api前缀
local influxdb_base_api = "http://" .. host .. ":" .. port
                          .. "/query?db=" .. db .. "&q="

local headers = {}
-- http basic 认证
if user ~= "" and password ~= "" then
    local auth_str = user .. ":" .. password
    local basic_auth = ngx_encode_base64(auth_str)
    headers["Authorization"] = "Basic " .. basic_auth
end


_M.query = function(sql)
    local query_api = influxdb_base_api .. sql

    local res, err = http.request(query_api,
                                  "GET",
                                  timeout,
                                  keepalive_timeout,
                                  keepalive_pool,
                                  headers)

    if not res then
        return response.db_err(err, sql)
    end

    local series_data = res.results[1]["series"]

    return series_data or {}
end


return _M
