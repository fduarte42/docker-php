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

echo "extension=phpchartdir${PHP_VERSION/\.//}0.dll" > /etc/php/${PHP_VERSION}/mods-available/chartdirector.ini
phpenmod chartdirector
