# 项目名称

`use-openresty` - 基于`OpenResty`的`Web API`脚手架.

## 主要特性

* 不同于大多数其他`OpenResty Web`框架只利用`OpenResty`的`Content`执行阶段,
  使用本框架开发的每一个业务`API`都可以使用各自希望用到的`OpenResty`执行阶段.
* 简易的路由配置, 路由配置从`nginx.conf`文件中分离出来, 并自动重定向去除请求的尾部`/`.
* 封装常用的数据库调用模型: `Redis`、`MySQL`、`InfluxDB`、`OrientDB`.
* 封装`mlcache`三级缓存(`lrucache->sharedict->callback`),
  方便对响应数据或过程碎片数据进行缓存.
* 集成基础的`waf`功能: 白名单、请求方法过滤、请求并发数限制等.
* 支持热更新, 当`*.conf`或`*.lua`文件有变化时, 会自动对`OpenResty`进行reload.
* 侵入式框架, 建议直接作为项目根目录使用, 充分利用框架提供的代码.
* 可快速开始新的项目逻辑编写, 做到不写重复代码, 快速地交付高性能高质量的应用.
* 适用于编写高性能高并发的中小型`Web API`项目.

## 架构解析

### 全局目录结构

`tree -L 1 use-openresty`

```txt
use-openresty
├── README.md
├── app  # 具体应用的Lua代码所在目录, MVC结构Web API框架
├── conf  # ngxin.conf配置文件所在目录
├── html  # 静态文件所在目录
├── lib  # 自定义Lua库所在目录
├── logs  # Nginx日志文件所在目录
└── tplib  # 第三方Lua库所在目录
```

> 注:
> 之所以把第三方库拿出来放到`tplib`目录,
> 而不是保持通过`luarocks`或`opm`安装到的默认目录, 是为了方便迁移和维护.

### 应用目录的结构

`tree app`

```txt
app
├── apis  # 业务API目录, MVC中的C. 每一个业务API都可以设置各自需要的OR执行阶段.
│   ├── app1
|       ├── example_api1.lua  # 某一个应用的业务API文件.
|       ...
│   ├── ...
├── config.lua  # 应用的全局配置文件.
├── cache.lua  # 缓存模块, 便捷的对数据进行缓存.
├── main.lua  # 整个应用的入口文件.
├── models  # 模型, 获取后端数据, MVC中的M.
│   ├── influxdb  # InfluxDB模型模块所在目录.
│   ├── influxdb.lua  # InfluxDB HTTP API驱动.
│   ├── mysql
│   ├── mysql.lua  # 对官方resty.mysql的封装.
│   ├── orientdb
│   ├── orientdb.lua  # OrientDB HTTP API驱动.
│   └── redis.lua  # 对官方resty.redis的封装.
├── response.lua  # 响应模块, 模块化响应的输出格式.
├── router.⇵lua  # 路由模块, 配置urlpath和业务api的对应关系.
├── views  # MVC中的V, 这里用于测试API json数据的展示效果.
│   └── tree-graph.html
└── waf.lua  # 应用的简易防火墙.
```

> 通过了解该简易`Web API`框架的各个组成部分,
> 可以非常方便地拿来复用写项目应用的业务`API`.

### 简易架构图

```txt
                  Users
                    ⇵
           --------------------
           |    Controller    |
           --------------------
           |   router.lua     |
           |       ↓          |
           |   apis/*.lua     |
           --------------------
               ↙︎           ↘︎
    ----------------    ----------------
    |    Model     |    |     View     |
    ----------------    ----------------
    | models/*.lua |    | views/*.html |
    ----------------    ----------------
            ⇵
    -------------------------------------
    |            DataBases              |
    -------------------------------------
    | MySQL/Redis/InfluxDB/OrientDB/... |
    -------------------------------------
```

## 配置

`conf/nginx.conf`的配置.

### Lua模块的搜索顺序

`require Lua模块`时的目录查找顺序, 见`nginx.conf`配置文件中的如下这段:

```nginx
init_by_lua_block {
    local conf_path = ngx.config.prefix()
    -- require模块时的模块查找路径
    package.path = conf_path .. "/app/?.lua;"  -- 应用自身的lua库
                   .. conf_path .. "/lib/?.lua;"  -- 自定义lua库
                   .. conf_path .. "/tplib/?.lua;"  -- 第三方lua库
                   .. package.path  -- OpenResty官方lua库

    main = require "main"
}
```

优先级为:

应用自身`Lua`模块>自定义`Lua`库模块>第三方`Lua`模块>官方`Lua`模块.

## location配置

我们开发的业务`API`用到了多少执行阶段就在这里写多少:

```nginx
location / {
    rewrite_by_lua_block {
        main.rewrite()
    }

    access_by_lua_block {
        main.access()
    }

    content_by_lua_block {
        main.content()
    }
}
```

静态文件的路由在这里单独指定, 不要和`app/router.lua`掺和在一起:

```nginx
location /static/ {
    root html;
}
```

## 开发Web API

在这里配置路由: `app/router.lua`

在这里写`Web API`: `app/apis/`, 里面有相应的简单示例供参考.

## 部署

### Linux

```bash
openresty -p /yourpath/use-openresty
```

### MacOS

```bash
openresty -p /yourpath/use-openresty -c conf/nginx.conf
```

### Docker

使用项目提供的`Dockerfile`文件:

```bash
cd use-openresty/

# 通过Dockerfile文件创建项目的容器镜像
docker build -t use-openresty .

# 运行容器, 开发环境下将项目路径挂载到容器中, 使容器中的项目保持最新
docker run --rm --name useor -v $PWD:/app -p80:80 -d use-openresty
```

或者直接运行:

```bash
docker run --rm --name useor \
    -v $PWD:/app \
    -p 80:80 \
    -d openresty/openresty:alpine \
    /usr/local/openresty/bin/openresty -p /app -c conf/nginx.conf -g "daemon off;"
```

### 测试效果

http://localhost/

http://localhost/static/test.html

http://localhost/test

http://localhost/v1/app1/examples

http://localhost/v1/app1/examples/1

## 授权许可

本项目采用`MIT`开源授权许可证, 完整的授权说明已放置在[LICENSE](LICENSE)文件中.
