-- 三级缓存机制
-- Level1: resty.lrucache | worker level | reload will lose all cache data
-- Level2: ngx.shared.DICT | server level | reload won't lose cache data
-- Level3: callback function | server level| like redis、mysql、network io ...

local ngx = require "ngx"

-- https://github.com/thibaultcha/lua-resty-mlcache
local mlcache = require "resty.mlcache"

local response = require "response"
local resp_cache_seconds = require "config".resp_cache_seconds

local ngx_log = ngx.log
local ngx_ERR = ngx.ERR


local _M = {}
_M.name = "cache"
_M._VERSION = "0.1"


-- 对响应的缓存
local get_resp_cache = function()
    -- 第一个参数是mlcache实例的命名空间;
    -- 第二个参数是nginx.conf配置中的sharedict内存空间;
    -- 主动刷新缓存的场景需要设置ipc_shm参数.
    local resp_cache, err = mlcache.new("cache1", "resp_cache", {
        lru_size = 1000,  -- size of the L1 (Lua VM) cache, default is 100.
        ttl = resp_cache_seconds,  -- ttl for hits, default is 30s.
        neg_ttl = 30,  -- 30s ttl for misses, default is 5s.
        ipc_shm = "ipc_shm",  -- Inter-Process-Communication
    })

    if not resp_cache then
        ngx_log(ngx_ERR, "could not create mlcache: ", err)
        return response.cache_err(err)
    end

    return resp_cache
end


-- 对后端返回的碎片数据的缓存
local get_common_cache = function()
    local common_cache, err = mlcache.new("cache2", "common_cache", {
        lru_size = 1e6,  -- 1000000
        ttl = 20,  -- 20s
        neg_ttl = 5,
    })

    if not common_cache then
        ngx_log(ngx_ERR, "could not create mlcache: ", err)
        return response.cache_err(err)
    end

    return common_cache
end


_M.get_resp_cache = get_resp_cache
_M.get_common_cache = get_common_cache


return _M
