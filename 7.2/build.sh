#!/usr/bin/env bash
set -e

DEBIAN_FRONTEND=noninteractive
TERM=dumb

apt-get update
apt-get upgrade -y
apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libxml2-dev \
    libbz2-dev \
    sudo \
    libc-client-dev \
    libkrb5-dev \
    libz-dev \
    libmemcached-dev \
    libmemcached11 \
    libmemcachedutil2
docker-php-ext-configure imap --with-kerberos --with-imap-ssl
docker-php-ext-install mysqli pdo pdo_mysql soap exif bz2 imap gettext bcmath
docker-php-ext-install -j$(nproc) iconv
docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
docker-php-ext-install -j$(nproc) gd

# Memcached
pecl install memcached
echo extension=memcached.so > /usr/local/etc/php/conf.d/memcached.ini

# Install LDAP extension
apt-get install -y libldap2-dev
ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/
docker-php-ext-install ldap

# Install opcache
docker-php-ext-install opcache

# Install Intl-Extension
apt-get install -y libicu-dev && docker-php-ext-install intl

# Hide errors
echo "display_errors=off" > /usr/local/etc/php/conf.d/errors.ini
echo "log_errors=on" >> /usr/local/etc/php/conf.d/errors.ini

# Install APCu
pecl install apcu
echo "extension=apcu.so" > /usr/local/etc/php/conf.d/apcu.ini
echo "apc.enable_cli = On" >> /usr/local/etc/php/conf.d/apcu.ini

a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod proxy
a2enmod proxy_http

# Install SSMTP
apt-get install -y ssmtp
echo 'sendmail_path = "/usr/sbin/ssmtp -t"' > /usr/local/etc/php/conf.d/mail.ini

# Set the time zone to the local time zone
echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
echo "date.timezone = Europe/Berlin" > /usr/local/etc/php/conf.d/timezone.ini

# PHP Typo3 Settings
echo "always_populate_raw_post_data = -1" > /usr/local/etc/php/conf.d/typo3.ini
echo "max_execution_time = 240" >> /usr/local/etc/php/conf.d/typo3.ini
echo "max_input_vars = 1500" >> /usr/local/etc/php/conf.d/typo3.ini
docker-php-ext-install zip
apt-get install -y graphicsmagick

# INSTALL curl
apt-get install -y curl

# Setup the Composer installer
curl -o /tmp/composer-setup.php https://getcomposer.org/installer
curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
mkdir /var/www/.composer && chown www-data:www-data /var/www/.composer

apt-get install -y git unzip

# Install ssh2 extension
apt-get install -y libssh2-1-dev
pecl -d preferred_state=alpha install ssh2-1.0
echo "extension=ssh2.so" > /usr/local/etc/php/conf.d/ssh2.ini

# Install xsl extension
apt-get install -y libxslt1-dev
docker-php-ext-install xsl

# Install wkhtmltopdf
sed -i "s/main/main contrib/g" /etc/apt/sources.list && apt-get update
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | debconf-set-selections
apt-get install -y build-essential xorg libssl-dev libxrender-dev libjpeg62 fontconfig ttf-mscorefonts-installer xfonts-base xfonts-75dpi curl wget
apt-get clean
apt-get autoremove -y
apt-get install -y wkhtmltopdf
apt-get install xvfb

# Install pngquant
cd /tmp
git clone --recursive https://github.com/pornel/pngquant.git
cd pngquant
make
make install
cd
rm -Rf /tmp/pngquant

# poppler
apt-get install -y poppler-utils

# keychain
apt-get install -y keychain

mkdir /root/.ssh
chmod 744 /root/.ssh

mkdir /var/www/.ssh
chown -R www-data:www-data /var/www/.ssh
chmod 744 /var/www/.ssh
mkdir /var/www/.keychain
chown -R www-data:www-data /var/www/.keychain

cp /root/.profile /var/www/.profile
chown -R www-data:www-data /var/www/.profile



# cron
apt-get install -y cron

# gnupg
apt-get install -y gnupg
mkdir /var/www/.gnupg
chown -R www-data:www-data /var/www/.gnupg
chmod 700 /var/www/.gnupg

# supervisord
apt-get install -y supervisor

exit 0
