FROM php:5.6-apache

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# pre-build
COPY scripts/.bashrc /root/.bashrc
COPY scripts/.bashrc /var/www/.bashrc
RUN chown -R www-data:www-data /var/www/.bashrc
COPY wkhtmltox-0.12.2.1_linux-jessie-amd64.deb /tmp/wkhtmltox-0.12.2.1_linux-jessie-amd64.deb

# build
COPY build.sh /build.sh
RUN bash /build.sh && rm /build.sh

# post-build
COPY scripts/cron-foreground /usr/local/bin/cron-foreground
RUN chmod 700 /usr/local/bin/cron-foreground
COPY scripts/docker-php-init /docker-php-init
RUN chmod 755 /docker-php-init
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# cleanup
RUN rm -rf /var/lib/apt/lists/*

VOLUME ["/var/www/html"]

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
