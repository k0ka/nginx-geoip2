ARG NGINX_VERSION=1.18.0

FROM nginx:${NGINX_VERSION} AS base

FROM base AS builder

# get default configure options
RUN	nginx -V 2>&1 | grep "configure arguments:" | cut -d" " -f3- >/tmp/configure_options

# add deb-src
RUN cat > /etc/apt/sources.list <<EOF
    deb http://archive.debian.org/debian buster main contrib non-free
    deb http://archive.debian.org/debian-security buster/updates main contrib non-free
    deb-src https://nginx.org/packages/debian/ buster nginx
EOF

# install needed packages
RUN	 apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
		libmaxminddb0 libmaxminddb-dev curl git build-essential dpkg-dev \
	&& apt-get build-dep -y nginx=${NGINX_VERSION}-${PKG_RELEASE}

# download sources
RUN mkdir /app \
	&& cd /app \
	&& apt-get source nginx=${NGINX_VERSION} \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git /app/ngx_http_geoip2_module \

# build
RUN cd /app/nginx-${NGINX_VERSION} \
	&& eval ./configure "$(cat /tmp/configure_options)" --add-dynamic-module=/app/ngx_http_geoip2_module \
	&& make 
	
FROM base

RUN \
	apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y libmaxminddb0 \
	&& apt-get purge -y --auto-remove

COPY --from=builder /app/nginx-${NGINX_VERSION}/objs/ngx_http_geoip2_module.so /usr/lib/nginx/modules/ngx_http_geoip2_module.so

MAINTAINER Konstantin Babushkin <k0ka@idwrx.com>


