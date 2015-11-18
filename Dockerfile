FROM ubuntu:14.04

MAINTAINER Richard Papp "contact@boromino.com"

RUN export DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y 	apache2 \
			php5 \
			php5-curl \
			php5-gd \
			php5-json \
			php5-mcrypt \
			php5-mysql \
			php-pear \
			php5-xdebug \
			mysql-client \
			ssmtp \
			curl \
			build-essential xorg \
			libssl-dev \
			libxrender-dev \
			wget \
			gdebi \
			tar \
			unzip \
			zip \
			ghostscript \
			git

# Set Apache environment variables (can be changed on docker run with -e)
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www/html

RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR
RUN echo "ServerName ${APACHE_SERVERNAME}" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite
COPY ./config/001-docker.conf /etc/apache2/sites-available/001-docker.conf
RUN a2dissite 000-default && a2ensite 001-docker

RUN php5enmod mcrypt
COPY ./config/php.ini /etc/php5/apache2/conf.d/00-php.ini
COPY ./config/xdebug.ini /etc/php5/mods-available/xdebug.ini

# Composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# Drush 8
RUN composer global require drush/drush:dev-master
RUN composer global update
RUN ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# ssmtp
COPY ./config/ssmtp.conf /etc/ssmtp/ssmtp.conf

# wkhtmltopdf
RUN wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
RUN gdebi --n wkhtmltox-0.12.2.1_linux-trusty-amd64.deb

# apt-cleanup
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 22 80 443

ENTRYPOINT ["/usr/sbin/apache2"]

CMD ["-D", "FOREGROUND"]
