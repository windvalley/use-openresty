local ngx_re_split = require "ngx.re".split

local influxdb_query = require "models.influxdb".query

local table_concat = table.concat


local _M = {}
_M.name = "example_cdn_bandwdith"
_M._VERSION = "0.1"


-- 用于判断请求查询的数据是否跨了多个月份，
-- 如果跨了月份，就将使用1h粒度的数据表(measurement).
local span_months = function(args)
    local timestart_table, _ = ngx_re_split(args.timestart, "-")
    local timeend_table, _ = ngx_re_split(args.timeend, "-")
    local timestart_month = timestart_table[2]
    local timeend_month = timeend_table[2]

    if timestart_month ~= timeend_month then
        return true
    end

    return false
end


-- 拼装sql where子句的一部分，用于参数的值是以逗号分隔的多个值的情况.
local function concat_argvalue_as_sqlpart(arg_key, arg_value)
    local value_list = ngx_re_split(arg_value, ",")
    local value_list_new = {}
    for i, value in ipairs(value_list) do
        local value_new = [["]] .. arg_key .. [["=']] .. value .. [[']]
        value_list_new[i] = value_new
    end

    local sql_part = table_concat(value_list_new, " or ")

    return "( " .. sql_part .. " )"
end


-- api的时间范围部分的sql
local get_sql_part_time = function(args)
    return [["time"<=']] .. args.timeend .. [[' and "time">=']]
           .. args.timestart .. [[']]
end


-- sql的结尾部分
-- 由于influxdb以utc时间存储数据，这里的tz表示以中国的时区取数据.
local sql_part_end = [[ fill(0) tz('Asia/Shanghai')]]


-- 获取数据的间隔时间
local get_elements = function(args, measurement)
    local time_interval = "5m"
    if span_months(args) then
        measurement = [[autogen."1h_]] .. measurement .. [["]]
        time_interval = "1h"
    end

    return measurement, time_interval
end


-- 获取服务器维度带宽的时序数据
_M.get_host_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    -- influxdb sql查询语句where子句中的host部分.
    local sql_part_host = concat_argvalue_as_sqlpart("host", args.host)

    local measurement_ = args.type .. "_bandwidth_host"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_host .. [[ group by time(]]
                .. time_interval .. [[), "host"]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取idc维度的带宽时序数据
_M.get_idc_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    -- influxdb sql查询语句where子句中的idc部分.
    local sql_part_idc = concat_argvalue_as_sqlpart("idc", args.idc)

    local measurement_ = args.type .. "_bandwidth_idc"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_idc .. [[ group by time(]]
                .. time_interval .. [[), "idc"]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取CDN类型的带宽时序数据
_M.get_cdn_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    local measurement_ = "allcdn_bandwidth_sumvalue"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth from ]]
                .. measurement
                .. [[ where ]]
                .. sql_part_time .. [[ and "cdn_type"=']]
                .. args.type .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取ISP维度的带宽时序数据
_M.get_isp_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    local measurement_ = args.type .. "_bandwidth_isp"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and "isp"=']]
                .. args.isp .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取region维度的带宽时序数据
_M.get_region_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    local measurement_ = args.type .. "_bandwidth_region"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and "region"=']]
                .. args.region .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取域名维度的带宽时序数据
_M.get_domain_series = function(args)
    local sql_part_time = get_sql_part_time(args)
    local sql_part_name = concat_argvalue_as_sqlpart("name", args.name)

    local measurement_ = args.type .. "_bandwidth_name"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_name .. [[ group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取地区-运营商维度的带宽时序数据
_M.get_region_isp_series = function(args)
    local sql_part_time = get_sql_part_time(args)

    local measurement_ = args.type .. "_bandwidth"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and "region"=']]
                .. args.region .. [[' and "isp"=']]
                .. args.isp .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取域名-运营商维度的带宽时序数据
_M.get_domain_isp_series = function(args)
    local sql_part_time = get_sql_part_time(args)
    local sql_part_name = concat_argvalue_as_sqlpart("name", args.name)

    local measurement_ = args.type .. "_bandwidth"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_name .. [[ and "isp"=']]
                .. args.isp .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取域名-地区维度的带宽时序数据
_M.get_domain_region_series = function(args)
    local sql_part_time = get_sql_part_time(args)
    local sql_part_name = concat_argvalue_as_sqlpart("name", args.name)

    local measurement_ = args.type .. "_bandwidth"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_name .. [[ and "region"=']]
                .. args.region .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


-- 获取域名-地区-运营商维度的带宽时序数据
_M.get_domain_region_isp_series = function(args)
    local sql_part_time = get_sql_part_time(args)
    local sql_part_name = concat_argvalue_as_sqlpart("name", args.name)

    local measurement_ = args.type .. "_bandwidth"
    local measurement, time_interval = get_elements(args, measurement_)

    local sql = [[select sum(bandwidth) as bandwidth,]]
                .. [[sum(percentage) as percentage from ]]
                .. measurement .. [[ where ]]
                .. sql_part_time .. [[ and ]]
                .. sql_part_name .. [[ and "region"=']]
                .. args.region .. [[' and "isp"=']]
                .. args.isp .. [[' group by time(]]
                .. time_interval .. [[)]]
                .. sql_part_end

    local series_data = influxdb_query(sql)

    return series_data
end


return _M
