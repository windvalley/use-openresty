local _M = {}

_M.name = "config"
_M._VERSION = "0.1"


-- 响应数据的默认缓存时间
_M.resp_cache_seconds = 3600*24


-- redis配置信息
_M.redis_conf = {
    host = "127.0.0.1",
    port = 6379,
    db_index = 0,
    auth = "your password",
    timeout = 2000, -- 2 seconds
    -- If this value is not "on",
    -- keepalive_max_idle_timeout and keepalive_pool_size will be "nil".
    keepalive = "on",
    keepalive_max_idle_timeout = 20000, -- 20 seconds
    keepalive_pool_size = 100,
}


-- mysql配置信息
_M.mysql_conf = {
    host = "127.0.0.1",
    port = 3306,
    db = "test1",
    user = "root",
    password = "123456",
    max_packet_size = 1024 * 1024,
    charset = "utf8",
    timeout = 2000, -- 2 second
    max_idle_timeout = 10000,
    pool_size = 100,
}


-- influxdb配置信息
_M.influxdb_conf = {
    host = "127.0.0.1",
    port = 8086,
    db = "cdn_bandwidth",
    user = "",
    password = "",
    timeout = 2000, -- 2 second
    keepalive_timeout = 10000,
    keepalive_pool = 50,
}


-- orientdb配置信息
_M.orientdb_conf = {
    host = "127.0.0.1",
    port = 2480,
    db = "graphdb",
    user = "dbread",
    password = "kx0Qot_fIn2Xdfda-f",
    timeout = 2000, -- 2 second
    keepalive_timeout = 10000,
    keepalive_pool = 50,
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
