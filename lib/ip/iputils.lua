local bit = require "bit"

local bit_tobit = bit.tobit
local bit_lshift = bit.lshift
local bit_band = bit.band
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local string_find = string.find
local string_sub = string.sub
local ipairs = ipairs
local tonumber = tonumber
local tostring = tostring
local type = type


local _M = {}
_M.name = "iputils"
_M._VERSION = "0.1"


local bin_masks = {}
for i=0, 32 do
    bin_masks[tostring(i)] = bit_lshift(bit_tobit((2^i)-1), 32-i)
end


local bin_inverted_masks = {}
for i=0, 32 do
    i = tostring(i)
    bin_inverted_masks[i] = bit_bxor(bin_masks[i], bin_masks["32"])
end


local function split_octets(input)
    local pos
    local prev = 0
    local octs = {}

    for i=1, 4 do
        pos = string_find(input, ".", prev, true)
        if pos then
            if i == 4 then
                return nil, "Invalid IP"
            end
            octs[i] = string_sub(input, prev, pos-1)
        elseif i == 4 then
            octs[i] = string_sub(input, prev, -1)
            break
        else
            return nil, "Invalid IP"
        end
        prev = pos + 1
    end

    return octs
end


local function unsign(bin)
    if bin < 0 then
        return 4294967296 + bin
    end
    return bin
end


local function split_cidr(input)
    local pos = string_find(input, "/", 0, true)
    if not pos then
        return {input}
    end
    return {string_sub(input, 1, pos-1), string_sub(input, pos+1, -1)}
end


local function ip2int(ip)
    if type(ip) ~= "string" then
        return nil, "IP must be a string"
    end

    local octets = split_octets(ip)
    if not octets or #octets ~= 4 then
        return nil, "Invalid IP"
    end

    local bin_octets = {}
    local bin_ip = 0

    for i,octet in ipairs(octets) do
        local bin_octet = tonumber(octet)
        if not bin_octet or bin_octet > 255 then
            return nil, "Invalid octet: "..tostring(octet)
        end
        bin_octet = bit_tobit(bin_octet)
        bin_octets[i] = bin_octet
        bin_ip = bit_bor(bit_lshift(bin_octet, 8*(4-i)), bin_ip)
    end

    bin_ip = unsign(bin_ip)

    return bin_ip, bin_octets
end


local function cidr2rangeint(cidr)
    local mask_split = split_cidr(cidr, '/')
    local net = mask_split[1]
    local mask = mask_split[2] or "32"
    local mask_num = tonumber(mask)

    if not mask_num or (mask_num > 32 or mask_num < 0) then
        return nil, "Invalid prefix: /"..tostring(mask)
    end

    local bin_net, err = ip2int(net)
    if not bin_net then
        return nil, err
    end

    local bin_mask = bin_masks[mask]
    local bin_inv_mask = bin_inverted_masks[mask]

    local lower = bit_band(bin_net, bin_mask)
    local upper = bit_bor(lower, bin_inv_mask)

    return unsign(lower), unsign(upper)
end


_M.ip2int = ip2int
_M.cidr2rangeint = cidr2rangeint


return _M
