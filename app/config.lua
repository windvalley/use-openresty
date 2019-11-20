local _M = {}

_M.name = "config"
_M._VERSION = "0.1"


-- 响应数据的默认缓存时间
_M.resp_cache_seconds = 3600*24


-- redis配置信息,
-- models/redis.lua 默认使用该配置.
_M.redis_conf = {
    host = "127.0.0.1",
    port = 6379,
    --db_index = 0,  -- default is 0.
    --auth = "",  -- if your redis has password, write here.
    --timeout = 1000,  -- default is 1 second.
    --keepalive = "on",  -- default on.
    --keepalive_max_idle_timeout = 10000,  -- default is 10 seconds;
                                           -- nil if keepalive="off".
    --keepalive_pool_size = 100,  -- default count is 100;
                                  -- nil if keepalive="off".
}


-- mysql配置信息,
-- models/mysql.lua 默认使用该配置.
_M.mysql_conf = {
    host = "127.0.0.1",  -- default is 127.0.0.1.
    port = 3306,  -- default is 3306.
    db = "test1",  -- no default value, must be set.
    --user = "root",  -- default is root.
    --password = "",  -- default is "".
    --max_packet_size = 1024*1024,  -- default is 1024*1024.
    --charset = "utf8",  -- default is utf8.
    --timeout = 1000, -- default is 1000, i.e. 1 second.
    --max_idle_timeout = 10000,  -- default is 10 seconds.
    --pool_size = 50,  -- default count is 50.
}


-- influxdb配置信息
_M.influxdb_conf = {
    host = "127.0.0.1",  -- default is 127.0.0.1.
    port = 8086,  -- default is 8086.
    db = "cdn_bandwidth",  -- no default value, must be set.
    --user = "",  -- default is "".
    --password = "",  -- default is "".
    --timeout = 2000, -- default is 2000, 2 seconds.
    --keepalive_timeout = 10000,  -- default is 10 seconds.
    --keepalive_pool = 50,  -- default count is 50.
}


-- orientdb配置信息
_M.orientdb_conf = {
    host = "127.0.0.1",  -- default is 127.0.0.1.
    port = 2480,  -- default is 2480.
    db = "graphdb",  -- no default value, must be set.
    user = "reader",  -- default is "".
    password = "123456",  -- default is "".
    --timeout = 2000, -- default is 2000, 2 seconds.
    --keepalive_timeout = 10000,  -- default is 10 seconds.
    --keepalive_pool = 50,  -- default is 50.
}


-- IP白名单, 全部注释将取消白名单策略
_M.ip_whitelist = {
    --"127.0.0.1",
    --"10.29.24.170",  -- kong
}


-- 鉴权
_M.authenticate = {
    auth_key = "56911a203de023998dbb8a3b718c6"
}


-- 用户请求并发限制
_M.request_limit = {
    limit = true,  -- 值为false, 将不启用限制
    limit_number_per_second = 1000,
    burst_number = 100,
}


return _M
