FROM php:8.0-apache-buster
ARG TARGETARCH

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
RUN chown -R www-data:www-data /var/www/.bashrc
COPY wkhtmltox_0.12.6-1.buster_$TARGETARCH.deb /tmp/wkhtmltox.deb
COPY ssmtp_2.64-8ubuntu2_$TARGETARCH.deb /tmp/ssmtp.deb

# build
COPY build.sh /build.sh
RUN bash /build.sh && rm /build.sh
COPY add-puppeteer.sh /add-puppeteer.sh
RUN bash /add-puppeteer.sh && rm /add-puppeteer.sh

# post-build
COPY scripts/cron-foreground /usr/local/bin/cron-foreground
RUN chmod 700 /usr/local/bin/cron-foreground
COPY scripts/docker-php-init /docker-php-init
RUN chmod 755 /docker-php-init
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY scripts/wkhtmltopdf /usr/local/bin/wkhtmltopdf
#RUN chmod 755 /usr/local/bin/wkhtmltopdf

# add intl packages
COPY add-intl.sh /add-intl.sh
RUN bash /add-intl.sh && rm /add-intl.sh

# cleanup
RUN rm -rf /var/lib/apt/lists/*

#VOLUME ["/var/www/html"]

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
