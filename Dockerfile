ARG NGINX_VERSION=1.26

FROM nginx:${NGINX_VERSION} AS base

ENV SUMMARY="Official nginx build with added ngx_http_geoip2 and ngx_lua modules" \
	DESCRIPTION="ngx_http_geoip2 module - creates variables with values from the maxmind geoip2 \
	    databases based on the client IP (default) or from a specific variable (supports both IPv4 and IPv6). \
	    ngx_lua module - adds lua support to nginx."

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

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-suggests --no-install-recommends \
                patch make wget git devscripts debhelper dpkg-dev \
                quilt lsb-release build-essential libxml2-utils xsltproc \
                equivs git g++ libparse-recdescent-perl \
    && git clone -b ${NGINX_VERSION}-${PKG_RELEASE%%~*} https://github.com/nginx/pkg-oss/ \
    && cd pkg-oss

COPY --chmod=755 xslscript.pl /pkg-oss/contrib/xslscript/

RUN mkdir /tmp/packages \
    && for module in geoip2 ndk lua; do \
        echo "Building $module from pkg-oss sources"; \
        cd /pkg-oss/debian; \
        make rules-module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
        mk-build-deps --install --tool="apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends --yes" debuild-module-$module/nginx-$NGINX_VERSION/debian/control; \
        make module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
        find ../../ -maxdepth 1 -mindepth 1 -type f -name "*.deb" -exec mv -v {} /tmp/packages/ \;; \
        BUILT_MODULES="$BUILT_MODULES $module"; \
    done \
    && echo "BUILT_MODULES=\"$BUILT_MODULES\"" > /tmp/packages/modules.env

FROM base

RUN --mount=type=bind,target=/tmp/packages/,source=/tmp/packages/,from=builder \
    apt-get update \
    && . /tmp/packages/modules.env \
    && for module in $BUILT_MODULES; do \
           apt-get install --no-install-suggests --no-install-recommends -y /tmp/packages/nginx-module-${module}_${NGINX_VERSION}*.deb; \
       done \
    && rm -rf /var/lib/apt/lists/ \
	&& apt-get purge -y --auto-remove


