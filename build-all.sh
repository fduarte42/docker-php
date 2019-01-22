#!/usr/bin/env bash
set -e

VERSIONS="5.3 5.5 5.6 7.0 7.1 7.2 7.3"

for V in $VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile -t fduarte42/docker-php:$V .
    docker build --no-cache -f Dockerfile-debug -t fduarte42/docker-php:$V-debug .
    cd ..
done

EXTRA_VERSIONS="7.2"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --no-cache -f Dockerfile-sqlsrv -t fduarte42/docker-php:$V-sqlsrv .
    docker build --no-cache -f Dockerfile-sqlsrv-debug -t fduarte42/docker-php:$V-sqlsrv-debug .
    cd ..
done

EXTRA_VERSIONS="7.2 7.3"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --no-cache -f Dockerfile-oci -t fduarte42/docker-php:$V-oci .
    docker build --no-cache -f Dockerfile-oci-debug -t fduarte42/docker-php:$V-oci-debug .
    cd ..
done

exit 0