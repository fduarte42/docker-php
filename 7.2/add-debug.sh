#!/usr/bin/env bash
set -e

# XDEBUG
pecl channel-update pecl.php.net
pecl install xdebug
echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.client_port=9000" >> /usr/local/etc/php/conf.d/xdebug.ini
echo 'xdebug.client_host="${XDEBUG_REMOTE_HOST}"' >> /usr/local/etc/php/conf.d/xdebug.ini
echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/xdebug.ini
echo "display_errors=on" >> /usr/local/etc/php/conf.d/xdebug.ini
