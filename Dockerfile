FROM	opensuse/tumbleweed:latest

RUN	zypper -n dup \
	&& zypper install -y --no-recommends curl ca-certificates gpg2 openssl \
	php7-fpm php7-APCu php7-gd php7-intl php7-mbstring php7-memcached php7-mysql \
	php7-opcache php7-tidy php7-xmlrpc php7-xsl php7-zip php7-zlib php7-bz2 php7-curl \
	php7-fastcgi php7-json python3-pip nano siege apache2-utils iputils \
	&& zypper clean -a \
	&& pip install --upgrade pip \
	&& pip install supervisor

COPY rootfs /

RUN chown -R wwwrun:www /srv/www/htdocs \
	&& chmod -R 775 /srv/www/htdocs \
	&& chown -R root:root /etc/nginx/modules \
	&& chmod -R 755 /etc/nginx/modules \
	&& chown root:root /usr/bin/nginx \
	&& chmod 755 /usr/bin/nginx \
	&& openssl dhparam -out /etc/nginx/dhparam.pem 2048


# be sure nginx is properly passing to php-fpm and fpm is responding
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f http://localhost/ping || exit 1

WORKDIR /srv/www/htdocs

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["supervisord" ]
