FROM php:7.2-apache

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \
        libbz2-dev \
        sudo \
        libc-client-dev \
        libkrb5-dev \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install mysqli pdo pdo_mysql soap exif bz2 imap gettext \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# Install LDAP extension
RUN apt-get install -y \
        libldap2-dev \
    && ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/ \
    && docker-php-ext-install ldap

# Install opcache
RUN docker-php-ext-install opcache

# Install Intl-Extension
RUN apt-get install -y libicu-dev && docker-php-ext-install intl

# Install APCu
RUN pecl install apcu
RUN echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini
RUN echo "apc.enable_cli = On" >> /usr/local/etc/php/conf.d/apcu.ini

RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod expires
RUN a2enmod proxy
RUN a2enmod proxy_http

# Install SSMTP
RUN apt-get install -y ssmtp
RUN echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

# Set the time zone to the local time zone
RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
RUN echo "date.timezone = Europe/Berlin" > /usr/local/etc/php/conf.d/timezone.ini

# PHP Typo3 Settings
RUN echo "always_populate_raw_post_data = -1" > /usr/local/etc/php/conf.d/typo3.ini
RUN echo "max_execution_time = 240" >> /usr/local/etc/php/conf.d/typo3.ini
RUN echo "max_input_vars = 1500" >> /usr/local/etc/php/conf.d/typo3.ini
RUN docker-php-ext-install zip
RUN apt-get install -y graphicsmagick

# INSTALL curl
RUN apt-get install -y curl

# Register the COMPOSER_HOME environment variable
ENV COMPOSER_HOME /composer

# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

# Allow Composer to be run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Setup the Composer installer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
RUN php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
RUN mkdir /var/www/.composer && chown www-data:www-data /var/www/.composer

RUN apt-get install -y git unzip

# Install ssh2 extension
RUN apt-get install -y libssh2-1-dev
RUN pecl -d preferred_state=alpha install ssh2-1.0
RUN echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ssh2.ini

# Install xsl extension
RUN apt-get install -y libxslt1-dev
RUN docker-php-ext-install xsl

# Install wkhtmltopdf
RUN sed -i "s/main/main contrib/g" /etc/apt/sources.list && apt-get update
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
        select true | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential xorg libssl-dev libxrender-dev libjpeg62 fontconfig ttf-mscorefonts-installer xfonts-base xfonts-75dpi curl wget \
    && apt-get clean \
    && apt-get autoremove -y
RUN apt-get install -y wkhtmltopdf

# Install pngquant
RUN cd /tmp \
    && git clone --recursive https://github.com/pornel/pngquant.git \
    && cd pngquant \
    && make \
    && make install \
    && cd \
    && rm -Rf /tmp/pngquant

# copy ssh key and autostart keychain on login
RUN apt-get install -y keychain

RUN mkdir /root/.ssh
RUN chmod 744 /root/.ssh
RUN echo '\nif [ -e "/ssh/id_rsa.pub" ]; then' >> /root/.bashrc
RUN echo '    cp /ssh/id_rsa.pub ~/.ssh/id_rsa.pub' >> /root/.bashrc
RUN echo '    chmod 644 /root/.ssh/id_rsa.pub' >> /root/.bashrc
RUN echo 'fi' >> /root/.bashrc
RUN echo '\nif [ -e "/ssh/id_rsa" ]; then' >> /root/.bashrc
RUN echo '    cp /ssh/id_rsa ~/.ssh/id_rsa' >> /root/.bashrc
RUN echo '    chmod 600 ~/.ssh/id_rsa' >> /root/.bashrc
RUN echo '    eval $(keychain --eval id_rsa)' >> /root/.bashrc
RUN echo 'fi' >> /root/.bashrc

RUN mkdir /var/www/.ssh
RUN chown -R www-data:www-data /var/www/.ssh
RUN chmod 744 /var/www/.ssh
RUN mkdir /var/www/.keychain
RUN chown -R www-data:www-data /var/www/.keychain
RUN cp /root/.profile /var/www/.profile
RUN chown -R www-data:www-data /var/www/.profile
RUN echo '\nif [ -e "/ssh/id_rsa.pub" ]; then' >> /var/www/.bashrc
RUN echo '    cp /ssh/id_rsa.pub /var/www/.ssh/id_rsa.pub' >> /var/www/.bashrc
RUN echo '    chmod 644 /var/www/.ssh/id_rsa.pub' >> /var/www/.bashrc
RUN echo 'fi' >> /var/www/.bashrc
RUN echo '\nif [ -e "/ssh/id_rsa" ]; then' >> /var/www/.bashrc
RUN echo '    cp /ssh/id_rsa /var/www/.ssh/id_rsa' >> /var/www/.bashrc
RUN echo '    chmod 600 /var/www/.ssh/id_rsa' >> /var/www/.bashrc
RUN echo '    eval $(keychain --eval /var/www/.ssh/id_rsa)' >> /var/www/.bashrc
RUN echo 'fi' >> /var/www/.bashrc
RUN chown -R www-data:www-data /var/www/.bashrc

# set term
RUN echo '\nexport TERM=xterm' >> /root/.bashrc
RUN echo '\nexport TERM=xterm' >> /var/www/.bashrc

# set composer home
RUN echo '\nexport COMPOSER_HOME=~/.composer' >> /root/.bashrc
RUN echo '\nexport COMPOSER_HOME=~/.composer' >> /var/www/.bashrc

# XDEBUG
RUN pecl install xdebug
RUN echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_connect_back=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo 'xdebug.remote_host="${XDEBUG_REMOTE_HOST}"' >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/xdebug.ini

# cron
RUN apt-get install -y cron
RUN echo '#!/bin/sh\n' > /usr/local/bin/cron-foreground
RUN echo 'if [ -e "/tmp/crontab" ]; then' >> /usr/local/bin/cron-foreground
RUN echo '    crontab -u www-data /tmp/crontab' >> /usr/local/bin/cron-foreground
RUN echo 'fi' >> /usr/local/bin/cron-foreground
RUN echo '\nexec cron -f -L 15' >> /usr/local/bin/cron-foreground
RUN chmod 700 /usr/local/bin/cron-foreground

# create init script
RUN echo '#!/bin/bash\n' > /docker-php-init.sh \
    && chmod 755 /docker-php-init.sh

RUN apt-get install -y gnupg \
    && mkdir /var/www/.gnupg \
    && chown -R www-data:www-data /var/www/.gnupg \
    && chmod 700 /var/www/.gnupg \
    && echo '\nif [ -e "/gnupg/gpg-key.asc" ]; then' >> /docker-php-init.sh \
    && echo '    sudo -u www-data gpg --import /gnupg/gpg-key.asc' >> /docker-php-init.sh \
    && echo 'fi' >> /docker-php-init.sh \
    && echo '\nif [ -e "/gnupg/gpg-secret-key.asc" ]; then' >> /docker-php-init.sh \
    && echo '    sudo -u www-data gpg --import /gnupg/gpg-secret-key.asc' >> /docker-php-init.sh \
    && echo 'fi' >> /docker-php-init.sh \
    && echo '\nif [ -e "/gnupg/trust.txt" ]; then' >> /docker-php-init.sh \
    && echo '    sudo -u www-data gpg --import-ownertrust /gnupg/trust.txt' >> /docker-php-init.sh \
    && echo 'fi' >> /docker-php-init.sh

# supervisord
RUN apt-get install -y supervisor
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf
RUN echo 'logfile=/var/log/supervisor/supervisord.log' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'pidfile=/var/run/supervisord.pid' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'loglevel=info' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf

RUN echo '\n[program:apache2]' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'command=/usr/local/bin/apache2-foreground' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'redirect_stderr=true' >> /etc/supervisor/conf.d/supervisord.conf

RUN echo '\n[program:cron]' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'command=/usr/local/bin/cron-foreground' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'redirect_stderr=true' >> /etc/supervisor/conf.d/supervisord.conf

RUN echo '\n[program:docker-php-init]' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'command=/docker-php-init.sh' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'autorestart=false' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'startsecs=0' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf
RUN echo 'redirect_stderr=true' >> /etc/supervisor/conf.d/supervisord.conf

VOLUME ["/var/www/html"]

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
