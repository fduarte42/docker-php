#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

cd /tmp

if [ "$TARGETARCH" = "arm64" ]; then
  tar xzf /tmp/chartdir_php_linux_arm64.tar.gz
fi

if [ "$TARGETARCH" = "amd64" ]; then
  tar xzf /tmp/chartdir_php_linux_64.tar.gz
fi

cp -R /tmp/ChartDirector/lib/* ${EXTENSION_DIR}
rm -R /tmp/ChartDirector

mkdir ${EXTENSION_DIR}/../lib
mv ${EXTENSION_DIR}/*.php /usr/local/lib/php

echo "extension=phpchartdir810.dll" > /usr/local/etc/php/conf.d/chartdirector.ini
