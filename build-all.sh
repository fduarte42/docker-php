#!/usr/bin/env bash
set -e

VERSIONS="5.3 5.5 5.6 7.0 7.1 7.2 7.3"
VERSIONS="7.0 7.1 7.2 7.3"

for V in $VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile -t fduarte42/docker-php:$V .
    docker build --no-cache -f Dockerfile-debug -t fduarte42/docker-php:$V-debug .
    cd ..
done
exit 0
EXTRA_VERSIONS="5.5"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile-tex -t fduarte42/docker-php:$V-tex .
    docker build --no-cache -f Dockerfile-tex-debug -t fduarte42/docker-php:$V-tex-debug .
    cd ..
done


EXTRA_VERSIONS="7.0 7.1 7.2 7.3"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile-chartdirector -t fduarte42/docker-php:$V-chartdirector .
    docker build --no-cache -f Dockerfile-chartdirector-debug -t fduarte42/docker-php:$V-chartdirector-debug .
    cd ..
done

EXTRA_VERSIONS="7.2 7.3"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile-ioncube_loader -t fduarte42/docker-php:$V-ioncube_loader .
    docker build --pull --no-cache -f Dockerfile-sourceguardian -t fduarte42/docker-php:$V-sourceguardian .

    docker build --pull --no-cache -f Dockerfile-oci -t fduarte42/docker-php:$V-oci .
    docker build --no-cache -f Dockerfile-oci-debug -t fduarte42/docker-php:$V-oci-debug .
    cd ..
done

EXTRA_VERSIONS="7.2"

for V in $EXTRA_VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile-sqlsrv -t fduarte42/docker-php:$V-sqlsrv .
    docker build --no-cache -f Dockerfile-sqlsrv-debug -t fduarte42/docker-php:$V-sqlsrv-debug .
    cd ..
done

exit 0