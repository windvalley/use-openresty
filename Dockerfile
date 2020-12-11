FROM openresty/openresty:1.19.3.1-alpine

WORKDIR /app
COPY . /app

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-p", "/app", "-c", "conf/nginx.conf", "-g", "daemon off;"]
