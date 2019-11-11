local ngx = require "ngx"
local cjson = require "cjson"

local config = require "config"
local cache = require "cache"

local cjson_encode = cjson.encode
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local table_concat = table.concat
local resp_cache = cache.get_resp_cache()
local resp_cache_seconds = config.resp_cache_seconds
local ngx_header = ngx.header


local _M = {}
_M.name = "response"
_M._VERSION = "0.1"


-- 正确的响应table
local ok_resp = {
    code = 200,
    msg = "ok",
    data = {},
}

-- 错误的响应table
local err_resp = {
    data = {},
}


-- 封装数据, 正常响应(不带缓存的响应)
_M.say_ok = function(data)
    ok_resp.data = data
    -- 即使nginx.conf没有配置响应类型, 也可以正常响应
    ngx_header.content_type = "application/json"
    ngx.say(cjson_encode(ok_resp))
end


-- 封装错误信息并响应, 由于不打算被外部模块调用, 所以没有封装到_M中.
local say_err = function(resp)
    ngx_header.content_type = "application/json"
    ngx.say(cjson_encode(resp))
    return ngx.exit(0)  -- 表示退出当前执行阶段
end


-- 主动更新缓存的响应
_M.update_say = function(cache_key, callback)
    local ttl, err, value, ok, data

    ttl, err, value = resp_cache:peek(cache_key)
    if err then
        ngx_log(ngx_ERR, "could not peek cache: ", err)
        return _M.internal_err(err)
    end

    -- 如果该cache_key的内容缓存时间还不满10分钟(还比较新鲜), 就先不触发更新,
    -- 而是继续使用现有缓存, 避免无意义的频繁刷新对数据库造成压力.
    local fresh_seconds = 600
    if ttl and (resp_cache_seconds-ttl) < fresh_seconds then
        _M.say_ok(value)
        return
    end

    ok, err = resp_cache:delete(cache_key)
    if not ok then
        ngx_log(ngx_ERR, "failed to delete value from cache: ", err)
        return _M.internal_err(err)
    end

    data, err = resp_cache:get(cache_key, nil, callback)
    if err then
        ngx_log(ngx_ERR, "could not retrieve data: ", err)
        return _M.internal_err(err)
    end

    _M.say_ok(data)
end


-- 正常使用缓存的响应
_M.cache_say = function(cache_key, callback)
    local ok, err, data

    -- 因为我们前面使用了缓存key删除机制delete, 所以这里需要先update(),
    -- 用来保证所有worker的lrucache(L1 cache)都保持最新.
    ok, err = resp_cache:update()
    if not ok then
        ngx_log(ngx_ERR, "failed to poll eviction events: ", err)
    end

    data, err = resp_cache:get(cache_key, nil, callback)
    if err then
        ngx_log(ngx_ERR, "could not retrieve data: ", err)
        return _M.internal_err(err)
    end

    _M.say_ok(data)
end


-- 请求的url不存在
_M.url_err = function(url)
    -- or前为使用数字作为错误码, or后为使用字符串作为错误码,
    -- 在这里当然 or 后面的永远不会被执行, 这么写只是提示一下,
    -- 如果团队规范允许, 使用字符串(大类:子类)作为错误码的方式可能更人性化一点.
    err_resp.code = 600 or "url:not_found"
    err_resp.msg = "url err: " .. url .. " not found."
    say_err(err_resp)
end


-- url参数错误
_M.arg_err = function()
    err_resp.code = 601 or "url:arg_error"
    err_resp.msg = "args err: no args or args value error."
    say_err(err_resp)
end


-- 请求方法不被允许
_M.method_err = function(method, allow_method_table)
    err_resp.code = 602 or "method:not_allowed"
    err_resp.msg = "method err: " .. method
                   .. " is not allowed, and allow methods: "
                   .. table_concat(allow_method_table, ",")
    say_err(err_resp)
end


-- 鉴权失败
_M.auth_err = function()
    err_resp.code = 603 or "auth:auth_failed"
    err_resp.msg = "authenticate failed."
    say_err(err_resp)
end


-- 用户查询的信息在db中不存在
_M.input_err = function(input)
    err_resp.code = 604 or "input:not_found"
    err_resp.msg = "input err, no such value: " .. input
    say_err(err_resp)
end


-- 内部错误: 查询db出现错误
_M.db_err = function(err, sql)
    ngx_log(ngx_ERR, "error: ", err, " sql: ", sql)
    err_resp.code = 605 or "internal:db_error"
    err_resp.msg = "internal err: db error."
    say_err(err_resp)
end


-- 内部错误: 缓存错误
_M.cache_err = function(err)
    ngx_log(ngx_ERR, "error: ", err)
    err_resp.code = 606 or "internal:cache_error"
    err_resp.msg = "internal err: cache error."
    say_err(err_resp)
end


-- 内部错误: 不明确的错误
_M.internal_err = function(err)
    ngx_log(ngx_ERR, "error: ", err)
    err_resp.code = 607 or "internal:unkown_error"
    err_resp.msg = "internal err: unknown."
    say_err(err_resp)
end


-- 响应html页面
_M.render = function(html)
    -- 由于nginx配置文件中配置的可能是"default_type application/json;",
    -- 这里必须加这个响应header以覆盖掉默认的配置, 确保浏览器正常解析html.
    ngx_header.content_type = "text/html"
    ngx.say(html)
end


return _M
