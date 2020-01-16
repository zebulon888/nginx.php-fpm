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

# SET php.ini ENV VAR's
ENV	PHP.zlib.output_compression = On \
	PHP.zlib.output_compression_level = 4 \
	PHP.max_input_time = 10 \
	PHP.memory_limit = 384M \
	PHP.error_reporting = 'E_ALL & ~E_DEPRECATED & ~E_STRICT' \
	PHP.display_errors = Off \
	PHP.display_startup_errors = Off \
	PHP.log_errors = On \
	PHP.log_errors_max_len = 1024 \
	PHP.ignore_repeated_errors = Off \
	PHP.ignore_repeated_source = Off \
	PHP.report_memleaks = On \
	PHP.post_max_size = 48M \
	PHP.default_charset = 'UTF-8' \
	PHP.file_uploads = On \
	PHP.upload_max_filesize = 16M \
	PHP.max_file_uploads = 20 \
	PHP.allow_url_fopen = On \
	PHP.allow_url_include = Off \
	PHP.default_socket_timeout = 60 \
	PHP.date.timezone = 'UTC' \
	PHP.SMTP = localhost \
	PHP.smtp_port = 25 \
	PHP.mail.add_x_header = Off \

# SET php-fpm.conf ENV VAR's
	FPM.pm=ondemand \
	FPM.pm.max_children=10 \
	FPM.pm.start_servers= \
	FPM.pm.min_spare_servers= \
	FPM.pm.max_spare_servers= \
	FPM.pm.process_idle_timeout=10s \
	FPM.pm.max_requests=0 \

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

EXPOSE 80 443 7890

STOPSIGNAL SIGTERM

CMD ["supervisord" ]
