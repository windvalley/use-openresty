-- 路由url对应的业务接口模块
local app1_examples_api1 = require "apis.app1.example_api1"
local app1_examples_api2 = require "apis.app1.example_api2"


local _M = {}

_M.name = "router"
_M._VERSION = "0.1"


-- 路由.
-- 规范起见, url路径结尾不要带/, 用户请求url如果结尾有/, 服务器会自动去掉/.
local url_path = {
    -- app1
    ["/v1/app1/examples"] = app1_examples_api1,
    -- 路径参数情况的写法
    ["/v1/app1/examples/[0-9]+"] = app1_examples_api2,
}


_M.url_path = url_path


return _M
