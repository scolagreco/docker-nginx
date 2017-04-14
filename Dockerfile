FROM scolagreco/docker-alpine:v3.4
MAINTAINER Stefano Colagreco <stefano@colagreco.it>

ENV NGINX_VERSION 1.10.3

ENV CONFIG "\
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-http_ssl_module \
	--with-http_realip_module \
	--with-http_addition_module \
	--with-http_sub_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_mp4_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_secure_link_module \
	--with-http_stub_status_module \
	--with-http_auth_request_module \
	--with-http_xslt_module=dynamic \
	--with-http_image_filter_module=dynamic \
	--with-http_geoip_module=dynamic \
	--with-http_perl_module=dynamic \
	--with-threads \
	--with-stream \
	--with-stream_ssl_module \
	--with-http_slice_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-file-aio \
	--with-http_v2_module \
	--with-ipv6 \
	"

ENV CFLAGS "-O2 -pipe -fomit-frame-pointer -march=core2 -mtune=intel"

COPY ./nginx-1.10.3.tar.gz /nginx.tar.gz

RUN 	addgroup -S nginx && \
	adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx && \
	apk add --update --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		openldap-dev \
		linux-headers \
		curl \
		gnupg \
		libxslt-dev \
		gd-dev \
		geoip-dev \
		perl-dev \
		&& \
	mkdir -p /usr/src && \
	tar -zxC /usr/src -f nginx.tar.gz && \
	rm nginx.tar.gz && \
        cd /usr/src/nginx-$NGINX_VERSION && \
	./configure $CONFIG && \
	make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
	make install && \
	strip /usr/sbin/nginx* && \
        apk add --update --no-cache --virtual .gettext gettext && \
	mv /usr/bin/envsubst /tmp/ && \
	runDeps="$( \
		scanelf --needed --nobanner /usr/sbin/nginx /tmp/envsubst \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| sort -u \
			| xargs -r apk info --installed \
			| sort -u \
	)" && \
	apk add --update --no-cache --virtual .nginx-rundeps $runDeps && \
	apk del .build-deps && \
        apk del .gettext && \
	mv /tmp/envsubst /usr/local/bin/ && \
	rm -rf /usr/src/nginx-* && \
	ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
