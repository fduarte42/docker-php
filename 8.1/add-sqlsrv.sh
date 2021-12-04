#!/usr/bin/env bash
set -e

# SSL
apt-get update
apt-get install apt-transport-https

# SQLSRV
curl -s http://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl http://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get -y install msodbcsql17 mssql-tools
apt-get -y install unixodbc-dev
pecl install sqlsrv
pecl install pdo_sqlsrv

echo "extension=sqlsrv.so" > /usr/local/etc/php/conf.d/sqlsrv.ini
echo "extension=pdo_sqlsrv.so" >> /usr/local/etc/php/conf.d/sqlsrv.ini
