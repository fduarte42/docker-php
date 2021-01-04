#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

cd /tmp
tar xzf /tmp/ioncube_loaders_lin_x86-64.tar.gz
cp -R /tmp/ioncube/* ${EXTENSION_DIR}
rm -R /tmp/ioncube

mkdir ${EXTENSION_DIR}/../lib
mv ${EXTENSION_DIR}/*.php /usr/local/lib/php

echo "zend_extension=ioncube_loader_lin_7.4.so" > /usr/local/etc/php/conf.d/_ioncube_loader.ini
