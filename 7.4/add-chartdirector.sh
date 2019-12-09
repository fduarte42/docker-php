#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

cd /tmp
tar xzf /tmp/chartdir_php_linux_64.tar.gz
cp -R /tmp/ChartDirector/lib/* ${EXTENSION_DIR}
rm -R /tmp/ChartDirector

mkdir ${EXTENSION_DIR}/../lib
mv ${EXTENSION_DIR}/*.php /usr/local/lib/php

echo "extension=phpchartdir730.dll" > /usr/local/etc/php/conf.d/chartdirector.ini
