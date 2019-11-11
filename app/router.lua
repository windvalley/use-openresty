-- 路由url对应的接口模块
local ip_graph = require "apis.ip_graph"
local front_ip_graph = require "apis.front_ip_graph"
local domain_graph = require "apis.domain_graph"
local front_domain_graph = require "apis.front_domain_graph"


local _M = {}

_M.name = "router"
_M._VERSION = "0.1"


-- 路由.
-- 注意这里写的是url path, 不要写url参数;
-- 另外, url path 结尾一定要加/, 防止匹配错误.
local url_path = {
    ["/orientdb/ip-graph/"] = ip_graph,
    ["/orientdb/front/ip-graph/"] = front_ip_graph,
    ["/orientdb/domain-graph/"] = domain_graph,
    ["/orientdb/front/domain-graph/"] = front_domain_graph,
}


_M.url_path = url_path


return _M
