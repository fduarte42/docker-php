#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
export TERM=linux

# init packages
apt update

apt -y install apt-transport-https lsb-release ca-certificates curl wget gnupg
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

sed -i 's/^Components: main$/& contrib non-free/' /etc/apt/sources.list.d/debian.sources

# node
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

apt update
apt upgrade -y

echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | debconf-set-selections

apt install -y \
  bzip2 \
  chromium \
  cron \
  curl \
  ffmpeg \
  git \
  gnupg \
  keychain \
  libapache2-mod-php${PHP_VERSION} \
  locales \
  htop \
  imagemagick \
  javascript-common \
  msmtp \
  nano-tiny \
  nodejs \
  openssh-server \
  php${PHP_VERSION} \
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
  pngquant \
  poppler-utils \
  rsyslog \
  sudo \
  supervisor \
  ttf-mscorefonts-installer \
  unzip \
  wkhtmltopdf \
  xfonts-75dpi \
  yarn

if [[ $PHP_VERSION =~ (7\.2|7\.4) ]]; then
  apt install -y \
    php${PHP_VERSION}-http \
    php${PHP_VERSION}-raphf \
    php${PHP_VERSION}-propro
else
  apt install -y \
    php${PHP_VERSION}-http \
    php${PHP_VERSION}-raphf
fi

update-alternatives --set php /usr/bin/php${PHP_VERSION}

# docker-template compatibility
mkdir -p /usr/local/etc/php/conf.d
touch /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /usr/local/etc/php/conf.d/zzz-custom.ini
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /etc/php/${PHP_VERSION}/apache2/conf.d
ln -s /etc/php/${PHP_VERSION}/mods-available/zzz-custom.ini /etc/php/${PHP_VERSION}/cli/conf.d
ln -s /usr/bin/php /usr/local/bin/php
ln -s /usr/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf

# apcu
if [[ $PHP_VERSION =~ (7\.2|7\.4) ]]; then
  apt install -y \
    php${PHP_VERSION}-apcu \
    php${PHP_VERSION}-apcu-bc
else
  apt install -y \
    php${PHP_VERSION}-apcu
fi

# apache disable unneeded config
a2disconf javascript-common

# Hide errors
echo "display_errors=off" > /etc/php/${PHP_VERSION}/mods-available/errors.ini
echo "log_errors=on" >> /etc/php/${PHP_VERSION}/mods-available/errors.ini
phpenmod errors

# session live time
mkdir -p /var/tmp/php-sessions
chown www-data:www-data /var/tmp/php-sessions
chmod 1770 /var/tmp/php-sessions
echo "session.gc_probability=1" > /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.gc_maxlifetime=\${PHP_GC_MAX_LIFETIME}" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.gc_divisor=1000" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
echo "session.save_path=/var/tmp/php-sessions" >> /etc/php/${PHP_VERSION}/mods-available/session_gc.ini
phpenmod session_gc

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

# apache enable modules
a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod proxy
a2enmod proxy_http

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
apt install -y ssmtp

# Set the time zone to the local time zone
echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
echo "date.timezone = Europe/Berlin" > /etc/php/${PHP_VERSION}/mods-available/timezone.ini
phpenmod timezone

# PHP Max Input Settings
echo "always_populate_raw_post_data = -1" > /etc/php/${PHP_VERSION}/mods-available/max_input.ini
echo "max_execution_time = 240" >> /etc/php/${PHP_VERSION}/mods-available/max_input.ini
echo "max_input_vars = 1500" >> /etc/php/${PHP_VERSION}/mods-available/max_input.ini
phpenmod max_input

# Settup git safe directory
echo -e "[safe]\n\tdirectory = *" > /var/www/.gitconfig
chown www-data:www-data /var/www/.gitconfig
chmod 660 /var/www/.gitconfig

# Setup the Composer installer
curl -o /tmp/composer-setup.php https://getcomposer.org/installer
curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig
php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }"

# Install Composer
if [[ $PHP_VERSION =~ (7\.2) ]]; then
  php /tmp/composer-setup.php --1 --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
else
  php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer && rm -rf /tmp/composer-setup.php
fi
mkdir -p /var/www/.composer && chown www-data:www-data /var/www/.composer

# Install psalm
composer global require vimeo/psalm

# Install phpcs
composer global require "squizlabs/php_codesniffer=*"

# Install composer-require-checker
composer global require maglnet/composer-require-checker

# replace wkthtmltopdf with patched qt version
if [ "$TARGETARCH" = "arm64" ]; then
  dpkg -i /tmp/wkhtmltox_*_arm64.deb
fi

if [ "$TARGETARCH" = "amd64" ]; then
  dpkg -i /tmp/wkhtmltox_*_amd64.deb
fi

rm /tmp/wkhtmltox_*.deb

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
