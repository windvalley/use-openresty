local ngx = require "ngx"
local cjson = require "cjson"


local redis = require "models.redis"
local config = require "config"
local response = require "response"


local cjson_encode = cjson.encode
local json_decode = cjson.decode
local ngx_md5 = ngx.md5
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR


local _M = {}

_M.name = "example_api_post"
_M._VERSION = "0.1"


local get_body_data = function()
    ngx.req.read_body()
    local body = ngx.req.get_body_data()
    local body_data_ = json_decode(body)
    local body_data = json_decode(body_data_)

    return body_data["time"], body_data["host"], body_data["data"]
end


_M.access = function()
    local ngx_ctx = ngx.ctx
    local headers = ngx.req.get_headers()
    ngx_ctx.headers = headers
end


_M.content = function()
    local red = redis:new()

    local logtime, loghost, logdata = get_body_data()

    local ok, err = red:hset("dl_" .. logtime, loghost, cjson_encode(logdata))
    local _, _ = red:expire("dl_" .. logtime, 36000)
    if not ok then
        return response.db_err(err, "write to redis error")
    end

    if logdata == "ErrorData" or not logdata then
        return response.data_err()
    end

    response.say_ok()
end


return _M

