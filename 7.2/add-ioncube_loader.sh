#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

# extract libs and sdk
cd /tmp

if [ "$TARGETARCH" = "arm64" ]; then
  tar xzf ioncube_loaders_lin_aarch64.tar.gz
fi

if [ "$TARGETARCH" = "amd64" ]; then
  tar xzf /tmp/ioncube_loaders_lin_x86-64.tar.gz
fi

cp -R /tmp/ioncube/* ${EXTENSION_DIR}
rm -R /tmp/ioncube

mkdir ${EXTENSION_DIR}/../lib
mv ${EXTENSION_DIR}/*.php /usr/local/lib/php

echo "zend_extension=ioncube_loader_lin_7.2.so" > /usr/local/etc/php/conf.d/_ioncube_loader.ini
