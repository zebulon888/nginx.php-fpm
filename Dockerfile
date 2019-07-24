FROM	opensuse/tumbleweed:latest

RUN	zypper -n up \
	&& zypper install -y --no-recommends curl ca-certificates gpg2 openssl \
	php7-fpm php7-APCu php7-gd php7-intl php7-mbstring php7-memcached php7-mysql \
	php7-opcache php7-tidy php7-xmlrpc php7-xsl php7-zip php7-zlib php7-bz2 php7-curl \
	php7-fastcgi php7-json python3-pip nano siege apache2-utils \
	&& chown -R wwwrun:www -R /srv/www/ \
	&& chmod -R 775 /srv/www/ \
	&& mkdir /srv/www/nginx \
	&& chown -R wwwrun:www /srv/www/nginx \
	&& chmod -R 775 /srv/www/nginx \
	&& zypper clean -a \
	&& pip install --upgrade pip \
	&& pip install supervisor

COPY rootfs /

# be sure nginx is properly passing to php-fpm and fpm is responding
HEALTHCHECK --interval=5s --timeout=3s \
  CMD curl -f http://localhost/ping || exit 1

WORKDIR /srv/www/htdocs

EXPOSE 80 443

CMD ["supervisord" ]

