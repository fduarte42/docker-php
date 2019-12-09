#!/usr/bin/env bash
set -e

apt-get update
apt-get install -y libaio1

# extract libs and sdk
unzip /tmp/instantclient-basic-linux.x64-18.3.0.0.0dbru.zip -d /opt/oracle
rm /tmp/instantclient-basic-linux.x64-18.3.0.0.0dbru.zip
unzip /tmp/instantclient-sdk-linux.x64-18.3.0.0.0dbru.zip -d /opt/oracle
rm /tmp/instantclient-sdk-linux.x64-18.3.0.0.0dbru.zip

# update ldconfig
echo /opt/oracle/instantclient_18_3 >> /etc/ld.so.conf
ldconfig

# install oci8
docker-php-ext-configure oci8 --with-oci8=shared,instantclient,/opt/oracle/instantclient_18_3
docker-php-ext-install oci8

# install pdo_oci
docker-php-ext-configure pdo_oci --with-pdo-oci=shared,instantclient,/opt/oracle/instantclient_18_3
docker-php-ext-install pdo_oci

