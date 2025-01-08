#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
export TERM=linux

# init packages
apt-get update

apt-get -y install apt-transport-https lsb-release ca-certificates curl wget gnupg
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

sed -i 's/^Components: main$/& contrib/' /etc/apt/sources.list.d/debian.sources

# node
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get remove -y --purge python3 python3-minimal python3.*
apt-get upgrade -y

apt-get install -y \
  apache2 \
  bzip2 \
  cron \
  curl \
  ffmpeg \
  git \
  gnupg \
  keychain \
  libapache2-mod-fcgid \
  locales \
  htop \
  imagemagick \
  javascript-common \
  msmtp \
  nano-tiny \
  nodejs \
  openssh-server \
  php${PHP_VERSION} \
  php${PHP_VERSION}-fpm \
  php${PHP_VERSION}-bcmath \
  php${PHP_VERSION}-bz2 \
  php${PHP_VERSION}-common \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-decimal \
  php${PHP_VERSION}-gd \
  php${PHP_VERSION}-imagick \
  php${PHP_VERSION}-imap \
  php${PHP_VERSION}-intl \
  php${PHP_VERSION}-ldap \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-memcached \
  php${PHP_VERSION}-mysql \
  php${PHP_VERSION}-opcache \
  php${PHP_VERSION}-pgsql \
  php${PHP_VERSION}-redis \
  php${PHP_VERSION}-soap \
  php${PHP_VERSION}-sqlite3 \
  php${PHP_VERSION}-ssh2 \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-xsl \
  php${PHP_VERSION}-zip \
  poppler-utils \
  rsyslog \
  sudo \
  supervisor \
  unzip \
  yarn

if [[ $PHP_VERSION =~ (7\.4) ]]; then
  apt-get install -y \
    php${PHP_VERSION}-http \
    php${PHP_VERSION}-raphf \
    php${PHP_VERSION}-propro
else
  apt-get install -y \
    php${PHP_VERSION}-http \
    php${PHP_VERSION}-raphf
fi

update-alternatives --set php /usr/bin/php${PHP_VERSION}

# docker-template compatibility
mkdir -p /usr/local/etc/php/conf.d
touch /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /usr/local/etc/php/conf.d/zzz-custom.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /etc/php/${PHP_VERSION}/fpm/conf.d
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /etc/php/${PHP_VERSION}/cli/conf.d
ln -s /usr/bin/php /usr/local/bin/php

# apcu
if [[ $PHP_VERSION =~ (7\.4) ]]; then
  apt-get install -y \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-apcu-bc
else
  apt-get install -y \
    php${PHP_VERSION}-apcu
fi

# apache enable modules
a2enmod proxy_fcgi setenvif
a2enconf php${PHP_VERSION}-fpm

# apache disable unneeded config
a2disconf javascript-common

# Hide errors
echo "display_errors=off" > /etc/php/${PHP_VERSION}/mods-available/errors.ini
echo "log_errors=on" >> /etc/php/${PHP_VERSION}/mods-available/errors.ini
phpenmod errors

# session live time
systemctl disable phpsessionclean.service
systemctl disable phpsessionclean.timer
mkdir -p /var/tmp/php-sessions
chown www-data:www-data /var/tmp/php-sessions
chmod 1770 /var/tmp/php-sessions
echo "session.gc_probability=1" > /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.gc_maxlifetime=\${PHP_GC_MAX_LIFETIME}" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.gc_divisor=1000" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.save_path=/var/tmp/php-sessions" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
phpenmod session_gc

# apache enable php-fpm for all .php files
echo "<FilesMatch \"\.php$\">" > /etc/apache2/conf-available/enable-php-handler.conf
echo "    SetHandler \"proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost/\"" >> /etc/apache2/conf-available/enable-php-handler.conf
echo "</FilesMatch>" >> /etc/apache2/conf-available/enable-php-handler.conf
a2enconf enable-php-handler

# apache enable .htaccess
echo "<Directory /var/www/html>" > /etc/apache2/conf-available/enable-htaccess.conf
echo "    AllowOverride All" >> /etc/apache2/conf-available/enable-htaccess.conf
echo "</Directory>" >> /etc/apache2/conf-available/enable-htaccess.conf
a2enconf enable-htaccess

# apache disable directory listing
echo "<Directory /var/www/html>" > /etc/apache2/conf-available/disable-dir-list.conf
echo "    Options -Indexes" >> /etc/apache2/conf-available/disable-dir-list.conf
echo "</Directory>" >> /etc/apache2/conf-available/disable-dir-list.conf
a2enconf disable-dir-list

# apache hide server signature
echo "ServerTokens Prod" > /etc/apache2/conf-available/hide-server-signature.conf
echo "ServerSignature Off" >> /etc/apache2/conf-available/hide-server-signature.conf
a2enconf hide-server-signature

# apache enable modules
a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod proxy
a2enmod proxy_http

# disable clear env for php fpm
sed -i "s/;clear_env = no/clear_env = no/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# add php fpm link for supervisor
ln -s /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm

# locales
LOCALES="en_US en_GB fr_FR es_ES pt_PT de_DE"
for L in $LOCALES; do
    localedef -i $L -c -f UTF-8 -A /etc/locale.alias $L.UTF-8
done

# setup npm
mkdir -p /root/.npm
mkdir -p /var/www/.npm
chown www-data:www-data /var/www/.npm

# install wait-for-it
curl -sL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh > /usr/sbin/wait-for-it.sh
chmod +x /usr/sbin/wait-for-it.sh

# ssmtp
apt-get install -y ssmtp

# Set the time zone to the local time zone
echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
echo "date.timezone = Europe/Berlin" > /etc/php/${PHP_VERSION}/mods-available/timezone.ini
phpenmod timezone

# PHP Max Input Settings
echo "always_populate_raw_post_data = -1" > /etc/php/${PHP_VERSION}/mods-available/max_input.ini
echo "max_execution_time = 240" >> /etc/php/${PHP_VERSION}/mods-available/max_input.ini
echo "max_input_vars = 1500" >> /etc/php/${PHP_VERSION}/mods-available/max_input.ini
phpenmod max_input

# Setup git safe directory
echo -e "[safe]\n\tdirectory = *" > /var/www/.gitconfig
chown www-data:www-data /var/www/.gitconfig
chmod 660 /var/www/.gitconfig

# allow bash history for www-data
touch /var/www/.bash_history
chown 600 /var/www/.bash_history
chown www-data:www-data /var/www/.bash_history

# allow www-data to reload apache
echo "www-data ALL = (root) NOPASSWD: /etc/init.d/apache2 reload" > /etc/sudoers.d/reload-apache

# Setup the Composer installer
curl -o /tmp/composer-setup.php https://getcomposer.org/installer
curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
mkdir -p /var/www/.composer && chown www-data:www-data /var/www/.composer

# Install psalm
composer global require vimeo/psalm

# Install phpcs
composer global require "squizlabs/php_codesniffer=*"

# Install composer-require-checker
if [[ $PHP_VERSION =~ (7\.4) ]]; then
    composer global require maglnet/composer-require-checker:3.8.0
else
    composer global require maglnet/composer-require-checker
fi

# setup keychain
mkdir -p /root/.ssh
chmod 744 /root/.ssh

mkdir -p /var/www/.ssh
chown -R www-data:www-data /var/www/.ssh
chmod 744 /var/www/.ssh
mkdir -p /var/www/.keychain
chown -R www-data:www-data /var/www/.keychain
touch /var/www/.selected_editor
chown www-data:www-data /var/www/.selected_editor

cp /root/.profile /var/www/.profile
chown -R www-data:www-data /var/www/.profile

# gnupg
mkdir -p /var/www/.gnupg
chown -R www-data:www-data /var/www/.gnupg
chmod 700 /var/www/.gnupg

# config
mkdir -p /var/www/.config
chown -R www-data:www-data /var/www/.config
chmod 744 /var/www/.config

# rsyslog
sed -i "s/module(load=\"imklog\")/#module(load=\"imklog\")/" /etc/rsyslog.conf

# cleanup
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*

exit 0
