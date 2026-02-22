ARG NGINX_VERSION=1.28

FROM nginx:${NGINX_VERSION} AS base

ENV SUMMARY="Official nginx build with ngx_http_geoip2_module" \
	DESCRIPTION="ngx_http_geoip2_module - creates variables with values from the maxmind geoip2 \
	    databases based on the client IP (default) or from a specific variable (supports both IPv4 and IPv6)."

LABEL maintainer="koka@idwrx.com" \
	summary="${SUMMARY}" \
	description="${DESCRIPTION}" \
	name="k0ka/nginx-geoip2"

RUN . /etc/os-release \
    && if [ "$VERSION_CODENAME" = "buster" ]; then \
        echo 'deb http://archive.debian.org/debian buster main contrib non-free' >/etc/apt/sources.list \
        && echo 'deb http://archive.debian.org/debian-security buster/updates main contrib non-free' >>/etc/apt/sources.list; \
    fi

FROM base AS builder

# get default configure options
RUN	nginx -V 2>&1 | grep "configure arguments:" | cut -d" " -f3- >/tmp/configure_options

RUN apt-get update \
    && apt-get install -y gnupg

# add nginx deb-src
RUN . /etc/os-release \
    && if command -v apt-key > /dev/null 2>&1; then \
        curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -; \
        echo "deb-src https://nginx.org/packages/debian/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list; \
    else \
        curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg; \
        echo "deb-src [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/debian/ ${VERSION_CODENAME} nginx" >> /etc/apt/sources.list; \
    fi

# add nginx sources
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
		libmaxminddb0 libmaxminddb-dev curl git build-essential dpkg-dev \
	&& apt-get build-dep -y nginx=${NGINX_VERSION}-${PKG_RELEASE}

# download sources
RUN mkdir /app \
	&& cd /app \
	&& apt-get source nginx=${NGINX_VERSION} \
    && git clone https://github.com/leev/ngx_http_geoip2_module.git /app/ngx_http_geoip2_module

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


