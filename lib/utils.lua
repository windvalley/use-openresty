local ngx = require "ngx"
local ngx_re_split = require("ngx.re").split

local ngx_now = ngx.now
local ngx_update_time = ngx.update_time
local ngx_log = ngx.log
local ngx_ERR = ngx.ERR
local io = io
local math_floor = math.floor
local table_insert = table.insert
local print = print


local _M = {}

_M.name = "utils"
_M._VERSION = "0.1"


-- 将文件加载到内存, 返回一个以换行符为分隔符的table数组.
local function loadfile_to_table(file)
    local f, err = io.open(file, "r")
    if not f then
        ngx_log(ngx_ERR, err)
    end

    local str = f:read("*a")
    local list = ngx_re_split(str, "\n")
    f:close()

    return list, err
end


-- 将文件加载到内存, 返回完整文件内容
local loadfile_to_ram = function(file)
    local f, err = io.open(file)
    if not f then
        ngx_log(ngx_ERR, err)
    end

    local content = f:read("*a")
    f:close()

    return content, err
end


-- 对函数进行性能测试, 参数说明:
-- funcname为需要打印的说明性文字;
-- func 为函数名称;
-- ...为函数func的参数.
local perf_time = function(funcname, func, ...)
    local time_old = ngx_now()
    local res = func(...)
    ngx_update_time()

    -- print用于resty脚本则将信息输出到屏幕,
    -- 如果用于服务器, 则将信息输出到error.log文件中(配置的日志级别需要在notice及以下才可以).
    print(funcname .. " use time: ", ngx_now() - time_old)

    return res
end


-- 二分搜索算法查询IP
local function ip_search(iptable, iptable_length, search_ipint)
    local low = 0
    -- Do not subtract 1, cos lua table index begin from 1.
    local height = iptable_length
    while low <= height do
        local mid = low + math_floor((height - low)/2)

        -- Lua table index begin from 1.
        local line_list
        if mid == 0 then
            line_list = ngx_re_split(iptable[mid+1], " ")
        else
            line_list = ngx_re_split(iptable[mid], " ")
        end

        local ip_start, ip_end = tonumber(line_list[1]), tonumber(line_list[2])
        if search_ipint < ip_start then
            height = mid - 1
        elseif search_ipint > ip_end then
            low = mid + 1
        else
            return line_list[3], line_list[4],
                   line_list[5], line_list[6], line_list[7]
        end
    end

    return nil, "IP not found."
end


-- 元素是否在table中存在
local item_if_in_table = function(item, tablename)
    for i=1, #tablename do
       if tablename[i] == item then
           return true
       end
    end
end


-- 截取table中的前top_number个元素
local table_top_slice = function(table_name, top_number)
    local n = 0
    local result_table = {}
    for _, v in ipairs(table_name) do
        if n == top_number then
            break
        end
        table_insert(result_table, v)
        n = n + 1
    end

    return result_table
end


_M.loadfile_to_table = loadfile_to_table
_M.loadfile_to_ram = loadfile_to_ram
_M.perf_time = perf_time
_M.ip_search = ip_search
_M.item_if_in_table = item_if_in_table
_M.table_top_slice = table_top_slice


return _M
