-- 官方模块
local ngx = require "ngx"
local mysql = require "resty.mysql"

-- 应用模块
local config = require "config"
local response = require "response"

-- 将函数缓存下来
local setmetatable = setmetatable
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR


local _M = {}
_M._VERSION = "0.1"
_M.name = "mysql"

local mt = { __index = _M }


-- 读取mysql的默认配置项
local host = config.mysql_conf["host"] or "127.0.0.1"
local port = config.mysql_conf["port"] or 3306
local database = config.mysql_conf["db"]
local user = config.mysql_conf["user"] or "root"
local password = config.mysql_conf["password"] or ""
local charset = config.mysql_conf["charset"] or "utf8"
local max_packet_size = config.mysql_conf["max_packet_size"] or 1024*1024

local timeout = config.mysql_conf["timeout"] or 1000
local max_idle_timeout = config.mysql_conf["max_idle_timeout"] or 10000
local pool_size = config.mysql_conf["pool_size"] or 50


-- 写这个new函数的目的是考虑到开发者可能不使用默认的配置去连接mysql,
-- 比如更换mysql的database等.
_M.new = function(self, new_conf)
    local conf = new_conf or {}

    local mysql_conf = {
        connect_conf = {
            host = conf.host or host,
            port = conf.port or port,
            database = conf.db or conf.database or database,
            user = conf.user or user,
            password = conf.password or password,
            charset = conf.charset or charset,
            max_packet_size = conf.max_packet_size or max_packet_size,
        },
        timeout = conf.timeout or timeout,
        max_idle_timeout = conf.max_idle_timeout or max_idle_timeout,
        pool_size = conf.pool_size or pool_size,
    }

    setmetatable(mysql_conf, mt)
    return mysql_conf
end


_M.exec = function(self, sql)
    local db, ok, res, err, errcode, errno, sqlstate

    -- get mysql object
    db, err = mysql:new()
    if not db then
        local err_msg = "failed to instantiate mysql: " .. err
        response.db_err(err_msg, sql)
    end

    -- set timeout
    db:set_timeout(self.timeout)

    -- connect mysql
    ok, err, errcode, sqlstate = db:connect(self.connect_conf)
    if not ok then
        local err_msg = "failed to connect: ".. err .. ": "
                        .. errcode .. " " .. sqlstate
        response.db_err(err_msg, sql)
    end

    --[[ 查看mysql连接池是否起作用.
      如果值为0, 说明是新建的连接, 还没有被重用过;
      如果值为非0的数字N, 说明该连接来自mysql连接池, 被重用了N次;
      已验证过, mysql连接池使用正常, 所以注释掉. ]]
    --ngx_log(ngx.ERR, "connected to mysql, reused_times:",
    --        db:get_reused_times(), " sql:", sql)

    db:query("SET NAMES utf8")

    -- execute sql
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        local err_msg = "bad result: " .. err .. ": " .. errno
                        .. ": " .. sqlstate .. "."
        response.db_err(err_msg, sql)
    end

    -- set keepalive
    ok, err = db:set_keepalive(self.max_idle_timeout, self.pool_size)
    if not ok then
        ngx_log(ngx_ERR, "failed to set keepalive: ", err)
        return
    end

    return res, err, errno, sqlstate
end


return _M
