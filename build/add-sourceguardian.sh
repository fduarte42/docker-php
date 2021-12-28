#!/usr/bin/env bash
set -e

EXTENSION_DIR=$(php -r "echo ini_get('extension_dir');")

mkdir /tmp/sourceguardian
cd /tmp/sourceguardian

if [ "$TARGETARCH" = "arm64" ]; then
  tar xjf ../loaders.linux-aarch64.tar.bz2
fi

if [ "$TARGETARCH" = "amd64" ]; then
  tar xjf ../loaders.linux-x86_64.tar.bz2
fi

cp -R ixed.${PHP_VERSION}.lin ${EXTENSION_DIR}
cd
rm -R /tmp/sourceguardian

echo "extension=ixed.${PHP_VERSION}.lin" > /etc/php/${PHP_VERSION}/mods-available/sourceguardian.ini
phpenmod sourceguardian
