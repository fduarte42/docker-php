#!/usr/bin/env bash
set -e

apt-get update
apt-get install -y libaio1



# extract libs and sdk
if [ "$TARGETARCH" = "arm64" ]; then
  unzip /tmp/instantclient-basic-linux.arm64-19.10.0.0.0dbru.zip -d /opt/oracle
  unzip /tmp/instantclient-sdk-linux.arm64-19.10.0.0.0dbru.zip -d /opt/oracle
  ln -s /opt/oracle/instantclient_19_10 /opt/oracle/instantclient
fi

if [ "$TARGETARCH" = "amd64" ]; then
  unzip /tmp/instantclient-basic-linux.x64-21.4.0.0.0dbru.zip -d /opt/oracle
  unzip /tmp/instantclient-sdk-linux.x64-21.4.0.0.0dbru.zip -d /opt/oracle
  ln -s /opt/oracle/instantclient_21_4 /opt/oracle/instantclient
fi

rm /tmp/*.zip

# update ldconfig
echo /opt/oracle/instantclient >> /etc/ld.so.conf
ldconfig

# install oci8
docker-php-ext-configure oci8 --with-oci8=shared,instantclient,/opt/oracle/instantclient
docker-php-ext-install oci8

# install pdo_oci
docker-php-ext-configure pdo_oci --with-pdo-oci=shared,instantclient,/opt/oracle/instantclient
docker-php-ext-install pdo_oci

