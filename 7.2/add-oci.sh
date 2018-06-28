#!/usr/bin/env bash
set -e

apt-get update
apt-get install -y libaio1

# extract libs and sdk
unzip /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip -d /opt/oracle
rm /tmp/instantclient-basic-linux.x64-12.2.0.1.0.zip
unzip /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip -d /opt/oracle
rm /tmp/instantclient-sdk-linux.x64-12.2.0.1.0.zip

# update ldconfig
echo /opt/oracle/instantclient_12_2 >> /etc/ld.so.conf
ldconfig

# add missing links
cd /opt/oracle/instantclient_12_2
ln -s libclntsh.so.12.1 libclntsh.so
ln -s libocci.so.12.1 libocci.so

# install oci8
docker-php-ext-configure oci8 --with-oci8=shared,instantclient,/opt/oracle/instantclient_12_2
docker-php-ext-install oci8

# install pdo_oci
docker-php-ext-configure pdo_oci --with-pdo-oci=shared,instantclient,/opt/oracle/instantclient_12_2
docker-php-ext-install pdo_oci

