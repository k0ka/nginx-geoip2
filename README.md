# nginx-geoip2

An image based on the official [nginx image](https://github.com/nginxinc/docker-nginx) with compiled [ngx_http_geoip2](https://github.com/leev/ngx_http_geoip2_module) and [ngx_lua](https://github.com/openresty/lua-nginx-module) modules.

Image is based on debian version nginx container.

The latest build of the image is on the GitHub. Use it as:
```shell
$ docker run -d \
  -v /data/nginx:/etc/nginx \
  ghcr.io/k0ka/nginx-geoip2:1.28
```