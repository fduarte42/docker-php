FROM php:7.0-apache

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libxml2-dev \
        libbz2-dev \
        sudo \
    && docker-php-ext-install mysqli pdo pdo_mysql soap exif bz2 \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# Install opcache
RUN docker-php-ext-install opcache

# Hide errors
RUN echo "display_errors=off" > /usr/local/etc/php/conf.d/errors.ini
RUN echo "log_errors=on" >> /usr/local/etc/php/conf.d/errors.ini

# Install APCu
RUN pecl install apcu
RUN echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini
RUN echo "apc.enable_cli = On" >> /usr/local/etc/php/conf.d/apcu.ini

RUN a2enmod rewrite

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

# copy ssh key and autostart keychain on login
RUN apt-get install -y keychain

RUN mkdir /root/.ssh
RUN chmod 644 /root/.ssh
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
RUN chmod 644 /root/.ssh
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

VOLUME ["/var/www/html"]

WORKDIR /var/www/html
