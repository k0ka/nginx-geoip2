ARG NGINX_VERSION=1.18.0

FROM nginx:${NGINX_VERSION} AS base

FROM base AS builder

RUN	\ 
# get default configure options
	nginx -V 2>&1 | grep "configure arguments:" | cut -d" " -f3- >/tmp/configure_options \
# add deb-src
	&& echo "deb-src https://nginx.org/packages/debian/ buster nginx" >>/etc/apt/sources.list \
# install needed packages
	&& apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		libmaxminddb0 libmaxminddb-dev curl git build-essential dpkg-dev \
	&& apt-get build-dep -y nginx=${NGINX_VERSION}-${PKG_RELEASE} \
# download sources
	&& mkdir /app \
	&& cd /app \
	&& apt-get source nginx=${NGINX_VERSION} \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git /app/ngx_http_geoip2_module \
# build
	&& cd /app/nginx-${NGINX_VERSION} \
	&& eval ./configure "$(cat /tmp/configure_options)" --add-dynamic-module=/app/ngx_http_geoip2_module \
	&& make 
	
FROM base

RUN \
	apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y libmaxminddb0 \
	&& apt-get purge -y --auto-remove

COPY --from=builder /app/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules/ngx_http_geoip2_module.so

MAINTAINER Konstantin Babushkin <k0ka@idwrx.com>


