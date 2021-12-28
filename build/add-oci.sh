#!/usr/bin/env bash
set -e

apt update
apt install -y libaio1

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

apt install -y php${PHP_VERSION}-dev

if [[ $PHP_VERSION =~ (7\.2|7\.4) ]]; then
  OCI_VERSION=2.2.0
elif [[ $PHP_VERSION =~ (8\.0) ]]; then
  OCI_VERSION=3.0.1
else
  OCI_VERSION=3.2.1
fi

# install oci8
cd /tmp
pecl download oci8-${OCI_VERSION}
tar xvzf oci8-${OCI_VERSION}.tgz
rm oci8-${OCI_VERSION}.tgz
cd oci8-${OCI_VERSION}
phpize
./configure --with-oci8=shared,instantclient,/opt/oracle/instantclient
make install
cd
rm -rf /tmp/oci8-${OCI_VERSION}

echo "extension=oci8.so" > /etc/php/${PHP_VERSION}/mods-available/oci8.ini
phpenmod oci8

apt remove -y php${PHP_VERSION}-dev

# cleanup
apt clean
apt autoremove -y
rm -rf /var/lib/apt/lists/*
