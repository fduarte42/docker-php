#!/usr/bin/env bash
set -e

# SQLSRV
curl -s http://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl http://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt -y install msodbcsql17 mssql-tools
apt-get -y install unixodbc-dev
pecl install sqlsrv
pecl install pdo_sqlsrv

echo "extension=sqlsrv.so" > /etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini
echo "extension=pdo_sqlsrv.so" >> /etc/php/${PHP_VERSION}/mods-available/sqlsrv.ini
phpenmod sqlsrv
