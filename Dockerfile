FROM alpine:3.6
ENV TIMEZONE UTC
ENV PUID=1000
ENV PGID=1000

RUN apk update --no-cache && apk upgrade
RUN apk add shadow \
    mariadb mariadb-client \
    apache2 \
    apache2-utils \
    curl wget vim htop \
    tzdata \
    php7-apache2 \
    php7-cli \
    php7-phar \
    php7-zlib \
    php7-zip \
    php7-bz2 \
    php7-ctype \
    php7-curl \
    php7-pdo_mysql \
    php7-mysqli \
    php7-json \
    php7-mcrypt \
    php7-xml \
    php7-dom \
    php7-iconv \
    php7-xdebug \
    php7-session \
    php7-intl \
    php7-gd \
    php7-mbstring \
    php7-apcu \
    php7-opcache \
    php7-tokenizer \
    php7-xmlwriter

RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/bin --filename=composer && \
    sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf
#    sed -i 's#Require all denied#Require all granted#' /etc/apache2/httpd.conf && \
#    sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/localhost/htdocs"#g' /etc/apache2/httpd.conf && \

# configure timezone, mysql, apache
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone && \
    mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=mysql --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null && \
    mkdir -p /run/apache2 && chown -R apache:apache /run/apache2 && chown -R apache:apache /var/www/localhost/htdocs/ && \
    sed -i 's#\#LoadModule rewrite_module modules\/mod_rewrite.so#LoadModule rewrite_module modules\/mod_rewrite.so#' /etc/apache2/httpd.conf && \
    sed -i 's#ServerName www.example.com:80#\nServerName localhost:80#' /etc/apache2/httpd.conf && \
    sed -i '/skip-external-locking/a log_error = \/var\/lib\/mysql\/error.log' /etc/mysql/my.cnf && \
    sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log = ON' /etc/mysql/my.cnf && \
    sed -i '/skip-external-locking/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/mysql/my.cnf

RUN sed -i 's#display_errors = Off#display_errors = On#' /etc/php7/php.ini && \
    sed -i 's#upload_max_filesize = 2M#upload_max_filesize = 100M#' /etc/php7/php.ini && \
    sed -i 's#post_max_size = 8M#post_max_size = 100M#' /etc/php7/php.ini && \
    sed -i 's#session.cookie_httponly =#session.cookie_httponly = true#' /etc/php7/php.ini && \
    sed -i 's#error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT#error_reporting = E_ALL#' /etc/php7/php.ini


# Configure xdebug
RUN echo "zend_extension=xdebug.so" > /etc/php7/conf.d/xdebug.ini && \
    echo -e "\n[XDEBUG]"  >> /etc/php7/conf.d/xdebug.ini && \
    echo "xdebug.remote_enable=1" >> /etc/php7/conf.d/xdebug.ini && \
    echo "xdebug.remote_connect_back=0" >> /etc/php7/conf.d/xdebug.ini && \
    echo "xdebug.idekey=PHPSTORM" >> /etc/php7/conf.d/xdebug.ini && \
    echo "xdebug.remote_host=host.docker.internal" >> /etc/php7/conf.d/xdebug.ini && \
    echo "xdebug.remote_log=\"/tmp/xdebug.log\"" >> /etc/php7/conf.d/xdebug.ini

RUN groupadd --gid "${PGID}" -r docker && \
    useradd -u "${PUID}" -r -g docker -c "Docker Image User" docker && \
    sed -i 's/User apache/User docker/g' /etc/apache2/httpd.conf && \
    sed -i 's/Group apache/Group docker/g' /etc/apache2/httpd.conf


COPY entry.sh /entry.sh

RUN chmod u+x /entry.sh

WORKDIR /var/www/localhost/htdocs/

EXPOSE 80
EXPOSE 3306

ENTRYPOINT ["/entry.sh"]
