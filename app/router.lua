-- 路由url对应的接口模块
local example_api = require "apis.example_api"
local front_example_api = require "apis.front_example_api"


local _M = {}

_M.name = "router"
_M._VERSION = "0.1"


-- 路由.
-- 注意这里写的是url path, 不要写url参数;
-- 另外, url path 结尾一定要加/, 防止匹配错误.
local url_path = {
    ["/api/example-api/"] = example_api,
    ["/api/front/example-api/"] = front_example_api,
}


_M.url_path = url_path


return _M
