local ngx = require "ngx"
local redis = require "resty.redis"

local redis_conf = require "config".redis_conf

local setmetatable = setmetatable
local rawget = rawget
local ipairs = ipairs
local unpack = unpack
local table_remove = table.remove
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR


local _ok, table_new = pcall(require, "table.new")
if not _ok or type(table_new) ~= "function" then
    table_new = function(_, _) return {} end
end


local _M = table_new(0, 54)

_M.name = "redis"
_M._VERSION = "0.1"

local mt = { __index = _M }


local host_default = redis_conf["host"] or "127.0.0.1"
local port_default = redis_conf["port"] or 6379
local db_index_default = redis_conf["db_index"] or 0
local auth_default = redis_conf["auth"] or nil
local timeout_default = redis_conf["timeout"] or 1000 -- 1 second
local keepalive_default = redis_conf["keepalive"] or "on"
local keepalive_max_idle_timeout_default =
    redis_conf["keepalive_max_idle_timeout"] or 10000 -- 10 seconds
local keepalive_pool_size_default =
    redis_conf["keepalive_pool_size"] or 100 -- count


local redis_connect = function(self)
    local red = redis:new()
    red:set_timeout(self.timeout)

    local ok, err
    ok, err = red:connect(self.host, self.port)
    if not ok then
        return nil, err
    end

    local auth = rawget(self, "auth")
    if auth and auth ~= "" then
        local count
        count, err = red:get_reused_times()
        if not count then
            ngx_log(ngx_ERR, "redis get_reused_times error: ", err)
        end

        if count == 0 then
            ok, err = red:auth(auth)
            if not ok then
                return nil, err
            end
        end
    end

    if self.db_index > 0 then
        ok, err = red:select(self.db_index)
        if not ok then
            return nil, err
        end
    end

    return red, nil
end


local redis_release = function(self, red)
    local keepalive = rawget(self, "keepalive")
    local keepalive_max_idle_timeout = rawget(self,
                                              "keepalive_max_idle_timeout")
    local keepalive_pool_size = rawget(self, "keepalive_pool_size")

    if keepalive == keepalive_default then
        local ok, err = red:set_keepalive(keepalive_max_idle_timeout,
                                          keepalive_pool_size)
        if not ok then
            return nil, err
        end
        return ok, nil
    end

    local ok, err = red:close()
    if not ok then
        return nil, err
    end

    return ok, nil
end


local do_cmd = function(self, cmd, ...)
    local reqs = rawget(self, "_pipe_reqs")
    if reqs then
        reqs[#reqs+1] = {cmd, ...}
        return
    end

    local red, err = redis_connect(self)
    if not red then
        return nil, err
    end

    -- Execute redis command.
    local method = red[cmd]
    local result
    result, err = method(red, ...)
    if not result then
        return nil, err
    end

    local ok
    ok, err = redis_release(self, red)
    if not ok then
        return nil, err
    end

    return result, nil
end


_M.init_pipeline = function(self, n)
    self._pipe_reqs = table_new(n or 4, 0)
end


_M.cancel_pipeline = function(self)
    self._pipe_reqs = nil
end


_M.commit_pipeline = function(self)
    local reqs = self._pipe_reqs
    if reqs == nil or #reqs == 0 then
        return {}, "no pipeline"
    end

    self._pipe_reqs = nil  -- reset

    local red, err = redis_connect(self)
    if not red then
        return nil, err
    end

    red:init_pipeline()

    for _, cmd in ipairs(reqs) do
        local func = red[cmd[1]]
        table_remove(cmd, 1)

        func(red, unpack(cmd))
    end

    local results
    results, err = red:commit_pipeline()
    if not results then
        return {}, err
    end

    local ok
    ok, err = redis_release(self, red)
    if not ok then
        return nil, err
    end

    return results, nil
end


_M.subscribe = function(self, channel)
    local red, err = redis_connect(self)
    if not red then
        return nil, err
    end

    local res
    res, err = red:subscribe(channel)
    if not res then
        return nil, err
    end

    res, err = red:red_reply()
    if not res then
       return nil, err
    end

    res, err = red:unsubscribe(channel)
    if not res then
        return nil, err
    elseif res[1] ~= "unsubscribe" then
        repeat
            res, err = red:read_reply()
            if not res then
                return nil, err
            end
        until res[1] == "unsubscribe"
    end

    local ok
    ok, err = redis_release(self, red)
    if not ok then
        return nil, err
    end

    return res, nil
end


--[[ _opts i.e., must be a table, and items can be none or many.
_opts = {
    host = "127.0.0.1",
    port = 6380,
    db_index = 1,
    auth = "your password",
    timeout = 2000, -- 2 seconds
    -- If this value is not "on",
    -- keepalive_max_idle_timeout and keepalive_pool_size will be "nil".
    keepalive = "off",
    keepalive_max_idle_timeout = 20000, -- 20 seconds
    keepalive_pool_size = 200,
}
]]
_M.new = function(self, _opts)
    local opts = _opts or {}
    local host = opts.host or host_default
    local port = opts.port or port_default
    local db_index = opts.db_index or db_index_default
    local auth = opts.auth or auth_default
    local timeout = opts.timeout or timeout_default
    local keepalive = opts.keepalive or keepalive_default
    local keepalive_max_idle_timeout =
        opts.keepalive_max_idle_timeout or keepalive_max_idle_timeout_default
    local keepalive_pool_size =
        opts.keepalive_pool_size or keepalive_pool_size_default

    if keepalive ~= keepalive_default then
        keepalive_max_idle_timeout = nil
        keepalive_pool_size = nil
    end

    local red = {
        host      = host,
        port      = port,
        db_index  = db_index,
        auth      = auth,
        timeout   = timeout,
        keepalive_max_idle_timeout = keepalive_max_idle_timeout,
        keepalive_pool_size = keepalive_pool_size,
        _pipe_reqs = nil, -- For pipeline requests to redis.
    }

    setmetatable(red, mt)
    return red
end


local function func(self, cmd)
    local function method(self, ...)
        return do_cmd(self, cmd, ...)
    end

    _M[cmd] = method
    return method
end


setmetatable(_M, { __index = func })


return _M
