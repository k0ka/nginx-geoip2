# nginx-geoip2

An image based on official [nginx image](https://github.com/nginxinc/docker-nginx) with compiled [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module).

Image is based on nginx:1.18.0 (buster)

The latest build of the image is on the GitHub. Use it as:
```shell
$ docker run -d \
  -v /data/nginx:/etc/nginx \
  ghcr.io/k0ka/nginx-geoip2
```