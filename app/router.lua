-- 路由url对应的业务接口模块
local app1_examples_api1 = require "apis.app1.example_api1"
local app1_examples_api2 = require "apis.app1.example_api2"


local _M = {}

_M.name = "router"
_M._VERSION = "0.1"


-- 路由.
-- 规范起见, url路径结尾不要带/,
-- Nginx已配置成如果用户请求的uri结尾有/, 将自动301重定向去掉/.
local url_path = {
    -- app1
    ["/v1/app1/examples"] = app1_examples_api1,
    -- 有路径参数情况的写法
    ["/v1/app1/examples/[0-9]+"] = app1_examples_api2,
}


_M.url_path = url_path


return _M
