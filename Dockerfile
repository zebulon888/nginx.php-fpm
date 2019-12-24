# Image aim: contain the latest mainline version of NGINX, GOACCESS from source and default php7-fpm from openSUSE tumbleweed.

FROM	opensuse/tumbleweed:latest

# Install php7-fpm and system libraries needed for nginx, goaccess
RUN	zypper -n dup \
	&& zypper install -y --no-recommends curl ca-certificates shadow gpg2 openssl pcre zlib \
	php7-fpm php7-APCu php7-gd php7-intl php7-mbstring php7-memcached php7-mysql \
	php7-opcache php7-tidy php7-xmlrpc php7-xsl php7-zip php7-zlib php7-bz2 php7-curl \
 	php7-fastcgi php7-json ncurses libmaxminddb0 gettext python3-pip nano siege apache2-utils iputils \
	&& zypper clean -a \
	&& pip install --upgrade pip \
	&& pip install supervisor

# create user and group 'nginx'. Default user for php-fpm and nginx
RUN 	groupadd -g 101 nginx && useradd -d /var/lib/nginx -c 'NGINX http server' -M -u 101 -g 101 nginx \
	&& usermod -G 100 -a nginx

# copy binary, config files for nginx and goaccess
COPY 	rootfs /
COPY	--from=z8bulon/source-building:latest /usr/local/etc/goaccess /usr/local/etc/goaccess
COPY	--from=z8bulon/source-building:latest /usr/local/bin/goaccess /usr/local/bin/goaccess
COPY	--from=z8bulon/source-building:latest /srv/www/nginx /srv/www/nginx
COPY	--from=z8bulon/source-building:latest /usr/bin/nginx /usr/bin/nginx

# set directory permissions
RUN 	mkdir /var/log/nginx \
	&& chown -R nginx:nginx /srv/www/htdocs \
	&& chmod -R 755 /srv/www \
	&& openssl dhparam -out /etc/nginx/dhparam.pem 2048


# be sure nginx is properly passing to php-fpm and fpm is responding
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f http://localhost/ping || exit 1

WORKDIR /srv/www/htdocs

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["supervisord" ]
