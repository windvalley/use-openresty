# Name

`use-openresty` - A Web API scaffolding based on OpenResty.

[简体中文](README_ZH.md)

## Features

* Unlike most other OpenResty Web frameworks that only use the content execution phase of OpenResty, every business API developed using this framework can use the OpenResty execution phase that they want to use.
* Simple routing configuration, will automatically redirect to remove the tail of the request `/`.
* Wraps common database models: `Redis`, `MySQL`, `InfluxDB`, `OrientDB`.
* Wrapping `mlcache` three-level cache (`lrucache->sharedict->callback`) to facilitate caching of response data or process fragment data.
* Integrate basic `waf` functions: whitelist, request method filtering, request concurrency limit, etc.
* Support live reload, when the `*.conf` or `*.lua` file changes, it will automatically reload the `OpenResty`.
* Intrusive framework, recommended to be used directly as the root directory of the project, taking full advantage of the code provided by the framework.
* You can quickly start writing new project logic, so as not to write duplicate codes, and quickly deliver high-performance and high-quality applications.
* Suitable for writing high-performance and high-concurrency small and medium-sized `Web API` projects.

## Architecture

### Global structure

`tree -L 1 use-openresty`

```txt
use-openresty
├── README.md
├── app  # Application-specific Lua code directory, MVC architecture Web API framework
├── conf  # ngxin.conf
├── html  # static files
├── lib  # Customizing the Lua library directory
├── logs  # access and error logs
└── tplib  # Directory of third-party Lua libraries
```

> Notes:
> The reason for taking the third-party libraries out and putting them in the `tplib` directory, instead of keeping the default directory where they were installed via `luarocks` or `opm`, is to facilitate migration and maintenance.

### App structure

`tree app`

```txt
app
├── apis  # In the Web API directory, each API can set its own required OR execution phase
│   ├── app1
|       ├── example_api1.lua  # An API file of a specific application
|       ...
│   ├── ...
├── config.lua  # The global configuration file of the application
├── cache.lua  # Cache module, conveniently cache data
├── main.lua  # The entry file of the entire application
├── models  # Model, get back-end data
│   ├── influxdb  # InfluxDB
│   ├── influxdb.lua  # InfluxDB HTTP API driver
│   ├── mysql
│   ├── mysql.lua  # Encapsulation of the official resty.mysql
│   ├── orientdb
│   ├── orientdb.lua  # OrientDB HTTP API driver
│   └── redis.lua  # Encapsulation of the official resty.redis
├── response.lua  # Response module, output format for modular responses
├── router.lua  # Routing module, to configure the correspondence between urlpath and service api
├── views  # This is used to test the display of API json data
│   └── tree-graph.html
└── waf.lua  # Simple firewall for applications
```

> By understanding the components of this simple `Web API` framework, it is very easy to reuse the business `API` for writing project applications.

### Simple arch map

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

## Configure

Configuration of `conf/nginx.conf`.

### Lua module search order

For the directory lookup order when `require Lua module`, see the following paragraph in the `nginx.conf` configuration file:

```nginx
init_by_lua_block {
    local conf_path = ngx.config.prefix()
    -- Module lookup path for require modules
    package.path = conf_path .. "/app/?.lua;"  -- The application's own lua library
                   .. conf_path .. "/lib/?.lua;"  -- Custom lua library
                   .. conf_path .. "/tplib/?.lua;"  -- Third-party lua library
                   .. package.path  -- OpenResty official lua library

    main = require "main"
}
```

Priorities are:

The application's own `Lua` module > custom `Lua` library module > third-party `Lua` module > official `Lua` module.

## `location` part

We write here as many execution phases as our service API needed:

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

The routing of static files is specified here separately, and should not be mixed with `app/router.lua`:

```nginx
location /static/ {
    root html;
}
```

## Begin to develop Web API

Configure routing here: `app/router.lua`

Write Web API here: `app/apis/`, there are corresponding simple examples for reference.

## Deployment

### Linux

`openresty -p /yourpath/use-openresty`

### MacOS

`openresty -p /yourpath/use-openresty -c conf/nginx.conf`

### Test

http://localhost/

http://localhost/static/test.html

http://localhost/test

http://localhost/v1/app1/examples

http://localhost/v1/app1/examples/1

## License

This project is under the MIT License. See the [LICENSE](LICENSE) file for the full license text.
