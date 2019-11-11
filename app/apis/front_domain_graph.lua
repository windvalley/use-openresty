-- domain-graph api的前端展示

local ngx = require "ngx"

local loadfile_to_ram = require "utils".loadfile_to_ram

local waf = require "waf"
local response = require "response"

local ngx_var = ngx.var
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local ngx_re_sub = ngx.re.sub


local _M = {}

_M.name = "front_domain_graph"
_M._VERSION = "0.1"


_M.access = function()
    waf.deny_ip_access()
end


local ngx_prefix = ngx.config.prefix()

local template_file = ngx_prefix .. "app/views/tree-graph.html"
local content, err = loadfile_to_ram(template_file)
if not content then
    ngx_log(ngx_ERR, err)
    return
end


_M.content = function()
    --[==[
    local domain = ngx_var.arg_domain
    local expand = ngx_var.arg_expand
    if not expand then
        expand = true
    else
        expand = false
    end

    local level = ngx_var.arg_level
    if not level then
        level = 5
    end

    local api = [[/orientdb/domain-graph/?domain=]] .. domain
    local update = ngx_var.arg_update
    if update == "1" then
        api = api .. "&update=1"
    end

    local newstr, _, err = ngx_re_sub(content, "{{api}}", api)
    newstr, _, err = ngx_re_sub(newstr, "{{expand}}", expand)
    newstr, _, err = ngx_re_sub(newstr, "{{level}}", level)
    if not newstr then
        ngx_log(ngx_ERR, "error: ", err)
        return
    end

    response.render(newstr)
    ]==]
end


return _M
