-- @wxg


local table_insert = table.insert
local table_concat = table.concat
local tonumber = tonumber
local tostring = tostring
local type = type
local string_sub = string.sub
local string_format = string.format
local math_floor = math.floor
local math_max = math.max


local _M = {}

_M.name = "bigint"
_M._VERSION = "0.1"


local mod = 10000


local function get(a)
    local s = {a[#a]}
    for i=#a-1, 1, -1 do
    table_insert(s, string_format("%04d", a[i]))
    end
    return table_concat(s, "")
end


local function create(s)
    if type(s) == "number" then
        s = tostring(string_format("%.f", s))
    end

    local n, t, a = math_floor(#s/4), 1, {}
    if #s%4 ~= 0 then
        a[n+1], t = tonumber(string_sub(s, 1, #s%4), 10), #s%4+1
    end

    for i=n, 1, -1 do
        a[i], t = tonumber(string_sub(s, t, t+3), 10), t+4
    end

    return a
end


local function add(_a, _b)
    local a, b, c, t = create(_a), create(_b), create("0"), 0
    for i = 1, math_max(#a, #b) do
    t = t + (a[i] or 0) + (b[i] or 0)
    c[i], t = t%mod, math_floor(t/mod)
    end

    while t ~= 0 do
        c[#c+1], t = t%mod, math_floor(t/mod)
    end

    return get(c)
end


local function sub(_a, _b)
    local a, b, c, t = create(_a), create(_b), create("0"), 0
    for i=1, #a do
    c[i] = a[i] - t - (b[i] or 0)
    if c[i] < 0 then
            t, c[i] = 1, c[i]+mod
        else
            t = 0
        end
    end

    return get(c)
end


local function mul(_a, _b)
    local a, b, c, t = create(_a), create(_b), create("0"), 0
    for i=1, #a do
    for j=1, #b do
            t = t + (c[i+j-1] or 0) + a[i] * b[j]
            c[i+j-1], t = t%mod, math_floor(t/mod)
    end

    if t ~= 0 then
            c[i+#b], t = t + (c[i+#b] or 0), 0
        end
    end

    return get(c)
end


_M.add = add
_M.sub = sub
_M.mul = mul


return _M
