# Name

apior - 基于`OpenResty`的`Web API脚手架`, MVC简易框架.


# Features

* 不同于大多数其他`OpenResty Web框架`只利用OpenResty的`Content执行阶段`, 本框架的每一个`业务API`都可以使用各自希望用到的`OpenResty执行阶段`.
* 封装`mlcache`三级缓存(`lrucache->sharedict->callback`), 方便对各种数据进行缓存.
* 侵入式, Clone下来作为项目目录直接改来用.
* 没有把`SESSION/COOKIE/JWT`等功能封装进去, 可直接对接`API网关`来实现相关功能.
* 适用于中小型后端API项目.


## 框架基础目录用途说明

`tree -L 1 apior`
```vim
apior
├── README.md
├── app  # 应用的Lua代码所在目录, MVC结构Web API框架
├── conf  # ngxin.conf配置文件所在目录
├── html  # 静态文件所在目录
├── lib  # 自定义Lua库所在目录
├── logs  # Nginx日志文件所在目录
└── tplib  # 第三方Lua库所在目录
```


*注: 之所以把第三方库拿出来放到`tplib`目录, 而不是保持通过`luarocks`或`opm`安装到的默认目录, 是为了方便迁移和维护.*


## 应用目录(app)的代码结构说明(MVC)

`tree app`
```
app
├── apis  # 业务API目录, MVC中的C. 每一个业务API都可以设置各自需要的OR执行阶段.
│   ├── example_api.lua  # 某一个业务API文件.
│   ├── ...
├── config.lua  # 应用的全局配置文件.
├── cache.lua  # 缓存模块, 便捷的对数据进行缓存.
├── main.lua  # 整个应用的入口文件.
├── models  # 模型, 获取后端数据, MVC中的M.
│   ├── influxdb  # InfluxDB模型模块所在目录.
│   │   └── cdn_bandwidth.lua
│   ├── influxdb.lua  # InfluxDB HTTP API驱动.
│   ├── mysql
│   ├── mysql.lua  # 对官方resty.mysql的封装.
│   ├── orientdb
│   │   └── ip_domain.lua
│   ├── orientdb.lua  # OrientDB HTTP API驱动.
│   └── redis.lua  # 对官方resty.redis的封装.
├── response.lua  # 响应模块, 模块化响应的输出格式.
├── router.lua  # 路由模块, 配置urlpath和业务api带宽的对应关系.
├── views  # MVC中的V, 这里用于测试API json数据的展示效果.
│   ├── README.md
│   └── tree-graph.html
└── waf.lua  # 应用的简易防火墙.
```

通过了解该简易`Web API`框架的各个组成部分, 可以非常方便拿来复用写其他应用`业务API`.


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


# `conf/nginx.conf`

`require Lua模块`时的目录查找顺序, 见`nginx.conf`配置文件中的如下这段:

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

`应用自身Lua模块>自定义Lua库模块>第三方Lua模块>官方Lua模块`


# 运行项目

## Linux系统下
`openresty -p /yourpath/apior`

## MacOS系统下
`openresty -p /yourpath/apior -c conf/nginx.conf`

