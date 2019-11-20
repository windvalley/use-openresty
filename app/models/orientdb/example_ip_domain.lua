local ngx = require "ngx"
local table_nkeys = require "table.nkeys"

local orientdb_query = require "models.orientdb".query
local response = require "response"

local table_insert = table.insert


local _M = {}
_M.name = "example_ip_domain"
_M._VERSION = "0.1"


-- 获取ip类型
_M.get_iptype = function(ip)
    local sql = "match {class:IP,as:ip,where:(ip='" .. ip .. [[')} return ip.type as ip_type, ip.@class as ip_type_backup]]
    local result = orientdb_query(sql)

    -- 用户查询的ip从orientdb查不到
    if table_nkeys(result) == 0 then
        response.input_err(ip)
    end

    -- 考虑到部分IP的ip_type字段为null的情况
    local iptype_code
    if result[1].ip_type == ngx.null then
        local ip_type_backup = result[1].ip_type_backup
        if ip_type_backup == "VIP" then
            iptype_code = 4
        else
            iptype_code = 5
        end
    else
        iptype_code = result[1].ip_type
    end

    return iptype_code
end


-- 获取VIP端口列表
_M.get_vip_ports = function(vip)
    local sql = [[match {class:IP,as:vip, where:(ip=']] .. vip .. [[')}.outE("MapTo"){as:mapto} return distinct mapto.vip_port as vip_port]]
    local result = orientdb_query(sql)

    local vip_port = {}
    for i=1, #result do
        vip_port[i] = result[i].vip_port
    end

    return vip_port
end


-- 通过vip和vip端口查询对应的"rip:rip端口"
_M.get_vip_vs_rips = function(vip, vip_port)
    local sql = [[match {class:IP,as:vip, where:(ip=']] .. vip .. [[')}.outE("MapTo"){as:mapto,where:(vip_port=]] .. vip_port .. [[)}.inV(){as:rip}-bind->{as:bind} return distinct rip.ip as rip,mapto.rip_port as port ]]
    local result = orientdb_query(sql)

    local rip_ripport = {}
    for i=1, #result do
        local rip = result[i].rip
        local port = result[i].port
        rip_ripport[i] = rip .. ":" ..port
    end

    return rip_ripport
end


-- 获取VIP所属的IDC
_M.get_vip_idc = function(vip)
    local sql = [[match {class:IP, as:vip, where:(ip=']] .. vip .. [[')} return vip.idc as idc_name]]
    local result = orientdb_query(sql)
    if table_nkeys(result) == 0 then
        return "timeout"
    end

    local idc_name = result[1].idc_name

    return idc_name
end


-- 获取VIP所属的人
_M.get_vip_person = function(vip)
    local sql = [[match {class:IP, where:(ip=']] .. vip .. [[')}-ipmanager->{as:person} return distinct person.name as name,person.mail as mail]]
    local result = orientdb_query(sql)

    local persons = {}
    for i=1, #result do
        local name_mail = result[i].name .. ":" .. result[i].mail
        persons[i] = name_mail
    end

    return persons
end


-- 获取RIP的属性信息
_M.get_rip_properties = function(rip)
    local sql = [[match {class:IP,where:(ip=']] .. rip .. [[')}-Bind->{as:bind}.outE(){as:role}.inV(){as:person} return distinct person.name as name,person.mail as mail,role.role_name as role,bind.hostname as virtual_hostname,bind.real_server_name as real_server_name,bind.host_name_out as host_name_out, bind.host_name_in as host_name_in]]
    local result = orientdb_query(sql)
    if table_nkeys(result) == 0 then
        return {}
    end

    local vip_property = {}
    for k=1, #result do
       local dict = result[k]
       if dict.role == ngx.null then
           goto continue
       end

       local person = dict.role .. "-" .. dict.name .. ":" .. dict.mail
       table_insert(vip_property, person)

       ::continue::
    end

    local dict = result[1]
    local virtual = dict["virtual_hostname"]
    local real = dict["real_server_name"]
    local hostname_in = dict["host_name_in"]
    local hostname_out = dict["host_name_out"]

    -- 虚拟机的情况
    if virtual ~= ngx.null then
        local virtual_str = "虚拟机:" .. virtual
        table_insert(vip_property, virtual_str)
    end
    if real ~= ngx.null then
        local real_str = "宿主机:" ..  real
        table_insert(vip_property, real_str)
    end

    -- 物理机的情况
    if hostname_in ~= ngx.null and hostname_in ~= "" then
        local hostname_in_str = "内网主机名:" .. hostname_in
        table_insert(vip_property, hostname_in_str)
    end
    if hostname_out ~= ngx.null and hostname_out ~= "" then
        local hostname_out_str = "外网主机名:" .. hostname_out
        table_insert(vip_property, hostname_out_str)
    end

    return vip_property
end


-- 获取IP对应域名的解析线路view
_M.get_ip_resolve_view = function(ip)
    local sql = [[match {class:IP, where:(ip=']] .. ip .. [[')}.inE("resolveto"){as:resolve} return distinct resolve.view as view]]
    local result = orientdb_query(sql)

    local views = {}
    for i=1, #result do
        local view_name = result[i].view
        views[i] = view_name
    end

    return views
end


-- 获取西向CName的解析线路view
_M.get_west_cname_views = function(fqdn)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.inE("cname"){as:cname} return distinct cname.view as view]]
    local result = orientdb_query(sql)

    local views = {}
    for i=1, #result do
        local view_name = result[i].view
        views[i] = view_name
    end

    return views
end


-- 通过域名和西向cname的view, 获取对应的域名
_M.get_west_cname_domains = function(fqdn, view)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.inE("cname"){as:cname,where:(view=']] .. view .. [[')}.outV(){as:domain} return distinct domain.fqdn as fqdn]]
    local result = orientdb_query(sql)

    local domains = {}
    for i=1, #result do
        local domain_name = result[i].fqdn
        domains[i] = domain_name
    end

    return domains
end


-- 获取东向CName的解析线路view
_M.get_east_cname_views = function(fqdn)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.outE("cname"){as:cname} return distinct cname.view as view]]
    local result = orientdb_query(sql)

    local views = {}
    for i=1, #result do
        local view_name = result[i].view
        views[i] = view_name
    end

    return views
end


-- 通过域名和东向cname的view, 获取对应的域名
_M.get_east_cname_domains = function(fqdn, view)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.outE("cname"){as:cname,where:(view=']] .. view .. [[')}.inV(){as:domain} return distinct domain.fqdn as fqdn]]
    local result = orientdb_query(sql)

    local domains = {}
    for i=1, #result do
        local domain_name = result[i].fqdn
        domains[i] = domain_name
    end

    return domains
end


-- 获取A记录解析线路view
_M.get_a_views = function(fqdn)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.outE("resolveto"){as: a} return distinct a.view as view]]
    local result = orientdb_query(sql)

    local views = {}
    for i=1, #result do
        local view_name = result[i].view
        views[i] = view_name
    end

    return views
end


-- 通过域名和A记录的解析线路, 获取对应的"IP:IP类型"
_M.get_a_ips = function(fqdn, view)
    local sql = [[match {class:domain, where:(fqdn=']] .. fqdn .. [[')}.outE("resolveto"){as:a,where:(view=']] .. view .. [[')}.inV(){as:ip} return ip.ip as ip, ip.type as ip_type, ip.@class as ip_type_backup]]
    local result = orientdb_query(sql)

    local ip_iptypes = {}
    for i=1, #result do
        -- 考虑到部分IP的ip_type字段值为null的情况
        local iptype_code
        if result[i].ip_type == ngx.null then
            local ip_type_backup = result[i].ip_type_backup
            if ip_type_backup == "VIP" then
                iptype_code = 4
            else
                iptype_code = 5
            end
        else
            iptype_code = result[i].ip_type
        end

        local ip_iptype = result[i].ip .. ":" .. iptype_code
        ip_iptypes[i] = ip_iptype
    end

    return ip_iptypes
end


-- 通过IP和解析线路获取直接对应的域名
_M.get_ip_view_domains = function(ip, view_name)
    local sql = [[match {class:IP,as:vip, where:(ip=']] .. ip .. [[')}.inE("resolveto"){as:resolve,where:(view=']] .. view_name .. [[')}.outV(){as:domain} return distinct domain.fqdn as domain]]
    local result = orientdb_query(sql)

    local domains = {}
    for i=1, #result do
        local domain_name = result[i].domain
        domains[i] = domain_name
    end

    return domains
end


-- 获取RIP端口列表
_M.get_rip_ports = function(rip)
    local sql = [[match {class:IP, where:(ip=']] .. rip .. [[')}.inE("mapto"){as:mapto} return distinct mapto.rip_port as rip_port]]
    local result = orientdb_query(sql)

    local ports = {}
    for i=1, #result do
        local port = result[i].rip_port
        ports[i] = port
    end

    return ports
end


-- 通过RIP和RIP端口获取对应的"VIP:VIP端口"
_M.get_rip_vs_vips = function(rip, rip_port)
    local sql = [[match {class:IP,as:ip, where:(ip=']] .. rip .. [[')}.inE("mapto"){as:mapto,where:(rip_port=']] .. rip_port .. [[')}.outV(){as:vip} return distinct mapto.vip_port as port, vip.ip as vip]]
    local result = orientdb_query(sql)

    local vip_vipport = {}
    for i=1, #result do
        local vip = result[i].vip
        local port = result[i].port
        vip_vipport[i] = vip .. ":" .. port
    end

    return vip_vipport
end


-- 判断域名是否在orientdb中存在, result为{}则为不存在
_M.get_domain = function(fqdn)
    local sql = [[match {class:domain, as:domain, where:(fqdn=']] .. fqdn .. [[')} return domain.fqdn as fqdn]]
    local result = orientdb_query(sql)
    return result
end


return _M
