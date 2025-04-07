#!/usr/bin/env bash
set -e

# XDEBUG
apt update
apt install -y php${PHP_VERSION}-xdebug
echo "xdebug.mode=debug" > /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
echo "xdebug.start_with_request=trigger" >> /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
echo "xdebug.client_port=9000" >> /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
echo 'xdebug.client_host="${XDEBUG_REMOTE_HOST}"' >> /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
echo "xdebug.idekey=PHPSTORM" >> /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
echo "display_errors=on" >> /etc/php/${PHP_VERSION}/mods-available/xdebug-config.ini
phpenmod xdebug-config

#apt install -y php${PHP_VERSION}-uopz
#phpenmod uopz
#apt install -y php${PHP_VERSION}-pcov
#phpenmod pcov

# cleanup
apt-get clean
apt-get autoremove -y
rm -rf /var/lib/apt/lists/*
