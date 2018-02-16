#!/usr/bin/env bash
set -e

# XDEBUG
pecl install xdebug-2.5.5
echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.remote_autostart=on" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.remote_connect_back=off" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.remote_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini
echo 'xdebug.remote_host="${XDEBUG_REMOTE_HOST}"' >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/xdebug.ini