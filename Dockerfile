# Image aim: contain the latest mainline version of NGINX, GOACCESS from source and default php7-fpm from openSUSE tumbleweed.

FROM	opensuse/tumbleweed:latest

LABEL maintainer="Maintainers: <metanoeho@zebulon.nl>"

ENV NGINX_VERSION=1.21.6
ENV PHP-FPM_VERSION=7.4.21
ENV GOACCESS_VERSION=1.5.6
ENV UID=101
ENV GID=101
ENV GROUP_ADD=100
ENV TZ="Europe/Amsterdam"

# SET php.ini ENV VAR's
ENV	PHP.zlib.output_compression=On \
	PHP.zlib.output_compression_level=4 \
	PHP.max_input_time=60 \
	PHP.memory_limit=128M \
	PHP.error_reporting='E_ALL & ~E_DEPRECATED & ~E_STRICT' \
	PHP.display_errors=Off \
	PHP.display_startup_errors=Off \
	PHP.log_errors=On \
	PHP.log_errors_max_len=1024 \
	PHP.ignore_repeated_errors=Off \
	PHP.ignore_repeated_source=Off \
	PHP.report_memleaks=On \
	PHP.post_max_size=48M \
	PHP.default_charset='UTF-8' \
	PHP.file_uploads=On \
	PHP.upload_max_filesize=32M \
	PHP.max_file_uploads=20 \
	PHP.allow_url_fopen=On \
	PHP.allow_url_include=Off \
	PHP.default_socket_timeout=60 \
	PHP.date.timezone='Europe/Amsterdam' \
	PHP.SMTP=localhost \
	PHP.smtp_port=587 \
	PHP.mail.add_x_header=Off \
	PHP.opcache.enable=1 \
	PHP.opcache.validate_timestamps=1 \
	PHP.opcache.max_accelerated_files=10000 \
	PHP.opcache.memory_consumption=512 \
	PHP.opcache.interned_strings_buffer=16 \
	PHP.session.save_handler=files \
	PHP.session.save_path="/var/lib/php7" \
	PHP.session.gc_probability=1 \
	PHP.session.gc_divisor=1000
	
# SET php-fpm.conf & www.conf (pool) ENV VAR's
ENV	FPM.pid=/run/php-fpm.pid \
	FPM.error_log=/dev/stderr \
	FPM.log_level=warning \
	FPM.emergency_restart_threshold=10 \
	FPM.emergency_restart_interval=1m \
	FPM.process_control_timeout=10s \
	WWW.user=nginx \
	WWW.group=nginx \
	WWW.listen=/run/php-fpm.sock \
	WWW.listen.owner=nginx \
	WWW.listen.group=nginx \
	WWW.listen.mode=0660 \
	WWW.listen.allowed_clients=127.0.0.1 \
	WWW.pm=dynamic \
	WWW.pm.max_children=10 \
	WWW.pm.start_servers=3 \
	WWW.pm.min_spare_servers=2 \
	WWW.pm.max_spare_servers=5 \
	WWW.pm.process_idle_timeout=60s \
	WWW.pm.max_requests=200 

WORKDIR /srv/www/htdocs

# Install curl
RUN zypper install -y curl 
#    && curl -fsSL https://download.opensuse.org/tumbleweed/repo/oss/repodata/repomd.xml.key > /tmp/factory.key \
#    && rpm --import /tmp/factory.key \
#    && zypper addrepo --check --refresh --name "Factory" https://download.opensuse.org/repositories/openSUSE:Factory/standard/openSUSE:Factory.repo

# Install php7-imap from a different repo
RUN curl -fsSL https://download.opensuse.org/repositories/home:Padom/openSUSE_Tumbleweed/repodata/repomd.xml.key > /tmp/imap.key \
    && rpm --import /tmp/imap.key \
    && zypper addrepo --check --refresh --name "imap" https://download.opensuse.org/repositories/home:Padom/openSUSE_Tumbleweed/home:Padom.repo

# Install php7-fpm and system libraries needed for nginx, goaccess
RUN	zypper install -y --no-recommends ca-certificates shadow gpg2 openssl pcre zlib unzip wget \
	php7-fpm php7-APCu php7-ctype php7-gd php7-intl php7-mbstring php7-memcached php7-mysql \
	php7-opcache php7-tidy php7-xmlreader php7-xmlwriter php7-xsl php7-xmlrpc php7-xsl \
	php7-tokenizer php7-pdo php7-iconv php7-dom php7-calendar php7-exif php7-fileinfo php7-posix \
	php7-zip php7-zlib php7-bz2 php7-curl php7-fastcgi php7-json php7-imap ncurses libmaxminddb0 gettext \
	python3-pip nano siege apache2-utils iputils cron \
	&& zypper clean -a \
	&& pip install --upgrade pip \
	&& pip install supervisor

# create user and group 'nginx'. Default user for php-fpm and nginx
RUN	/usr/sbin/groupadd -r -g ${GID} nginx \
	&& /usr/sbin/useradd -r -s /sbin/nologin -c 'NGINX user' -d /var/lib/nginx -u ${UID} nginx \
	&& /usr/sbin/usermod -a -G nginx nginx

# copy binary, config files for nginx and goaccess
COPY 	rootfs /
COPY	--from=z8bulon/source-building:latest /usr/local/etc/goaccess /usr/local/etc/goaccess
COPY	--from=z8bulon/source-building:latest /usr/local/bin/goaccess /usr/local/bin/goaccess
COPY	--from=z8bulon/source-building:latest /usr/bin/nginx /usr/bin/nginx

# set directory permissions
RUN 	mkdir /srv/www/nginx && mkdir /var/log/nginx \
	&& chown -R nginx:nginx /srv/www/htdocs /srv/www/nginx \
	&& chmod -R 775 /srv/www /srv/www/nginx \
	&& openssl dhparam -out /etc/nginx/dhparam.pem 2048

# be sure nginx is properly passing to php-fpm and fpm is responding
HEALTHCHECK --interval=10s --timeout=3s \
  CMD curl -f http://localhost/ping || exit 1

EXPOSE 80 443

STOPSIGNAL SIGTERM

CMD ["supervisord" ]
