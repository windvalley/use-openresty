-- @wxg


local ngx_re_split = require("ngx.re").split
local bigint = require "ip.bigint"

local bigint_add = bigint.add
local table_concat = table.concat
local table_insert = table.insert
local string_find = string.find
local string_sub = string.sub
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local type = type
local print = print


local _M = {}
_M.name = "ipv6utils"
_M._VERSION = "0.1"


local hex_vs_bin = {
    ["0"] = "0000",
    ["1"] = "0001",
    ["2"] = "0010",
    ["3"] = "0011",
    ["4"] = "0100",
    ["5"] = "0101",
    ["6"] = "0110",
    ["7"] = "0111",
    ["8"] = "1000",
    ["9"] = "1001",
    A = "1010",
    a = "1010",
    B = "1011",
    b = "1011",
    C = "1100",
    c = "1100",
    D = "1101",
    d = "1101",
    E = "1110",
    e = "1110",
    F = "1111",
    f = "1111",
}


local ipv6_full = function(ipv6_addr)
    local ipv6_table = ngx_re_split(ipv6_addr, ":")

    for k, v in ipairs(ipv6_table) do
        if #v == 0 then
            ipv6_table[k] = "0000"
        elseif #v == 1 then
            ipv6_table[k] = "000" .. v
        elseif #v == 2 then
            ipv6_table[k] = "00" .. v
        elseif #v == 3 then
            ipv6_table[k] = "0" .. v
        end

        for _=1, 8 - #ipv6_table do
            table_insert(ipv6_table, "0000")
        end
    end

    return table_concat(ipv6_table, ":")
end


local ipv6_to_int = function(ipv6_addr)
    if #ipv6_addr ~= 39 then
        ipv6_addr = ipv6_full(ipv6_addr)
    end

    local ip_table_ = ngx_re_split(ipv6_addr, ":")
    local ip_str_ = table_concat(ip_table_, "")
    local ip_table = ngx_re_split(ip_str_, "")

    local bin_table_ = {}
    for _, v in ipairs(ip_table) do
        bin_table_[#bin_table_+1] = hex_vs_bin[v]
    end

    local bin_str = table_concat(bin_table_, "")
    local bin_table = ngx_re_split(bin_str, "")

    local value = 0
    local n = #bin_table - 1
    for _, v in ipairs(bin_table) do
        -- This if statement can improve performance for 5 times.
        if v == "1" then
            local bit_num = 2^n
            value = bigint_add(value, bit_num)
        end
        n = n - 1
    end

    return tonumber(value)
end


local ipv6_cidr_to_range = function(ipv6_cidr_addr)
    local function explode( string, divide )
        if divide == '' then return false end
        local pos, arr = 0, {}
        for st, sp in function()
                          return string_find(string, divide, pos, true)
                      end do
            table_insert(arr, string_sub(string, pos, st-1))
            pos = sp + 1
        end
        table_insert(arr, string_sub(string, pos))
        return arr
    end

    if not ipv6_cidr_addr then return print('invalid ip') end
    local a, _, ip, mask = ipv6_cidr_addr:find('([%w:]+)/(%d+)')
    if not a then return print('invalid ip') end

    local ipbits = explode(ip, ':')

    local zeroblock
    for k, v in pairs(ipbits) do
        if v:len() == 0 then
            zeroblock = k

        elseif v:len() < 4 then
            local padding = 4 - v:len()
            for _=1, padding do
                 ipbits[k] = 0 .. ipbits[k]
            end
       end
    end

    if zeroblock and #ipbits < 8 then
        ipbits[zeroblock] = '0000'
        local padding = 8 - #ipbits

        for _=1, padding do
            table_insert(ipbits, zeroblock, '0000')
        end
    end

    local indent = mask / 4
    local wildcardbits = {}
    for _=0, indent-1 do
        table_insert(wildcardbits, 'f')
    end

    for _=0, 31-indent do
        table_insert(wildcardbits, '0')
    end

    local count, index, wildcard = 1, 1, {}
    for _, v in pairs(wildcardbits) do
        if count > 4 then
            count = 1
            index = index + 1
        end

        if not wildcard[index] then wildcard[index] = '' end

        wildcard[index] = wildcard[index] .. v
        count = count + 1
    end

    local topip = {}
    local bottomip = {}
    for k, v in pairs(ipbits) do
        local topbit = ''
        local bottombit = ''
        for i = 1, 4 do
            local wild = wildcard[k]:sub(i, i)
            local norm = v:sub(i, i)
            if wild == 'f' then
                topbit = topbit .. norm
                bottombit = bottombit .. norm
            else
                topbit = topbit .. '0'
                bottombit = bottombit .. 'f'
            end
        end

        topip[k] = topbit
        bottomip[k] = bottombit
    end

    local start_ip = table_concat(topip, ":")
    local end_ip = table_concat(bottomip, ":")

    return start_ip, end_ip
end


local get_ip_type = function(ip)
    local R = {
        ERROR = "error",
        IPV4 = "ipv4",
        IPV6 = "ipv6",
        STRING = "string"
    }

    if type(ip) ~= "string" then return R.ERROR end

    local chunks = { ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$") }
    if (#chunks == 4) then
        for _,v in pairs(chunks) do
            if tonumber(v) > 255 then return R.STRING end
        end
        return R.IPV4
    end

    local addr = ip:match("^([a-fA-F0-9:]+)$")
    if addr ~= nil and #addr > 1 then
        local nc, dc = 0, false
        for chunk, colons in addr:gmatch("([^:]*)(:*)") do
            if nc > (dc and 7 or 8) then return R.STRING end
            if #chunk > 0 and tonumber(chunk, 16) > 65535 then
                return R.STRING
            end
            if #colons > 0 then
                if #colons > 2 then return R.STRING end
                if #colons == 2 and dc == true then return R.STRING end
                if #colons == 2 and dc == false then dc = true end
            end
            nc = nc + 1
        end
        return R.IPV6
    end

    return R.STRING
end


_M.ipv6_full = ipv6_full
_M.ipv6_to_int = ipv6_to_int
_M.ipv6_cidr_to_range = ipv6_cidr_to_range
_M.get_ip_type = get_ip_type


return _M
