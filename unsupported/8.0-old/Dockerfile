FROM php:8.0-apache-buster

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# pre-build
COPY config/keyboard /etc/default/keyboard
COPY scripts/.bashrc /root/.bashrc
COPY scripts/.bashrc /var/www/.bashrc
COPY scripts/cron-foreground /usr/local/bin/cron-foreground
COPY scripts/docker-php-init /docker-php-init
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# build
COPY build.sh /build.sh
RUN bash /build.sh && rm /build.sh

#VOLUME ["/var/www/html"]

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
