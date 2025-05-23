FROM debian:bookworm-slim
ARG TARGETARCH
ARG PHP_VERSION=7.4

ENV DEBIAN_FRONTEND=noninteractive

# add puppeteer config
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME=/composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH=/composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# Set PHP session max lifetime
ENV PHP_GC_MAX_LIFETIME=1440

ENV DOCUMENT_ROOT=/

# pre-build
COPY config/keyboard /etc/default/keyboard
COPY scripts/.bashrc /root/.bashrc
COPY scripts/.bashrc /var/www/.bashrc
RUN chown -R www-data:www-data /var/www/.bashrc
COPY scripts/php-fpm-reload.sh /usr/local/bin/php-fpm-reload.sh
RUN chmod 755 /usr/local/bin/php-fpm-reload.sh

COPY packages/wkhtmltox_*.deb /tmp/

# build
COPY build.sh /build.sh
RUN bash /build.sh && rm /build.sh

# post-build
COPY scripts/cron-foreground /usr/local/bin/cron-foreground
RUN chmod 700 /usr/local/bin/cron-foreground
COPY scripts/docker-php-init /docker-php-init
RUN chmod 755 /docker-php-init
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /var/www/html

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
