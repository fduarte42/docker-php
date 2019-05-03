#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

mkdir /tmp/sourceguardian
cd /tmp/sourceguardian
tar xzf /tmp/loaders.linux-x86_64.tar.gz
cp -R /tmp/sourceguardian/* ${EXTENSION_DIR}
rm -R /tmp/sourceguardian

echo "zend_extension=ixed.7.2.lin" > /usr/local/etc/php/conf.d/_sourceguardian.ini
