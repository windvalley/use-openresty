# Name

apior - 基于`OpenResty`的`web api脚手架`, MVC简易框架.


## 基础目录用途说明

- app/   # 应用的lua代码所在目录, mvc结构web api框架
- lib/  # 自定义lua库所在目录
- tplib/  # 第三方lua库所在目录
- conf/  # `ngxin.conf`配置文件所在目录
- html/  # 静态文件所在目录
- logs/  # nginx日志文件所在目录


*注: 之所以把第三方库拿出来放到`tplib`目录, 而不是保持通过`luarocks`或`opm`安装到的默认目录, 是为了方便迁移和维护.*


## 应用目录的代码结构说明(MVC)

`tree app`
```
app
├── apis  # 业务api目录, MVC中的C. 每一个业务api都可以设置各自需要的OR执行阶段.
│   ├── domain_graph.lua  # 某一个业务api文件.
│   ├── ...
├── config.lua  # 应用的全局配置文件.
├── main.lua  # 整个应用的入口文件.
├── models  # 模型, 获取后端数据, MVC中的M.
│   ├── influxdb  # influxdb模型模块所在目录.
│   │   └── cdn_bandwidth.lua
│   ├── influxdb.lua  # influxdb http api驱动.
│   ├── mysql
│   │   └── test.lua
│   ├── mysql.lua  # 对官方resty.mysql的封装
│   ├── orientdb
│   │   └── ip_domain.lua
│   ├── orientdb.lua  # orientdb http api驱动.
│   └── redis.lua  # 对官方resty.redis的封装.
├── response.lua  # 响应模块, 模块化响应的输出格式.
├── router.lua  # 路由模块, 配置urlpath和业务api带宽的对应关系.
├── views  # MVC中的V, 这里用于测试api json数据的展示效果.
│   ├── README.md
│   ├── radial-tree-graph.html
│   └── tree-graph.html
└── waf.lua  # 应用的简易防火墙.
```

通过了解该简易`web api`框架的各个组成部分, 可以非常方便拿来复用写其他应用业务api.


对应MVC架构图如下:

                   用户
                    ↕️
           --------------------
           | 控制器Controller |
           |   router.lua     |
           |      ⬇️           |
           |   apis/*.lua     |
           --------------------
              ↙️            ↘️
    --------------       --------------
    |  模型Model |       |  视图View  |
    |models/*.lua|       |views/*.html|
    --------------       --------------
          ⬇️
    ----------------------------------
    |        各种数据库              |
    |MySQL/Redis/InfluxDB/OrientDB...|
    ----------------------------------


# `require Lua模块`时的目录查找顺序

见nginx.conf配置文件中的如下这段:

```nginx
init_by_lua_block {
    local conf_path = ngx.config.prefix()
    -- require模块时的模块查找路径
    package.path = conf_path .. "/app/?.lua;"  -- 应用自身的lua库
                   .. conf_path .. "/lib/?.lua;"  -- 自定义lua库
                   .. conf_path .. "/tplib/?.lua;"  -- 第三方lua库
                   .. package.path  -- openresty官方lua库

    main = require "main"
}
```

优先级为:
应用自身lua模块>自定义lua库模块>第三方lua模块>官方lua模块


# 运行项目

## Linux系统下
`openresty -p /your-project-path`

## MacOS系统下
`openresty -p /your-project-path -c conf/nginx.conf`

