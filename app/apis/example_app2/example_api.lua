local ngx = require "ngx"

local waf = require "waf"
local example_api_post = require "apis.example_app2.example_api_post"
local example_api_get = require "apis.example_app2.example_api_get"

local ngx_req = ngx.req


local _M = {}

_M._VERSION = "0.1"
_M.name = "example_api"


local access_phase = {
    POST = example_api_post.access,
    GET = example_api_get.access,
}


local content_phase = {
    POST = example_api_post.content,
    GET = example_api_get.content,
}


_M.access = function()
    waf.method_allow{"GET", "POST"}

    local method = ngx_req.get_method()
    access_phase[method]()
end


_M.content = function()
    local method = ngx_req.get_method()
    content_phase[method]()
end


return _M
