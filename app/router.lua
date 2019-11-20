-- 路由url对应的业务接口模块
local app1_example_api = require "apis.example_app1.example_api"
local app1_front_example_api = require "apis.example_app1.front_example_api"
local app2_example_api = require "apis.example_app2.example_api"


local _M = {}

_M.name = "router"
_M._VERSION = "0.1"


-- 路由.
-- 注意这里写的是url path, 不要写url参数;
-- 另外, url path 结尾一定要加/, 防止匹配错误.
local url_path = {
    -- app1
    ["/api/app1/example-api/"] = app1_example_api,
    ["/api/app1/front/example-api/"] = app1_front_example_api,
    -- app2
    ["/api/app2/example-api/"] = app2_example_api,
}


_M.url_path = url_path


return _M
