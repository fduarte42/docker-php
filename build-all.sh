#!/usr/bin/env bash
set -e

VERSIONS="5.3 5.5 5.6 7.0 7.1 7.2"

for V in $VERSIONS; do
    cd $V
    docker build --pull --no-cache -f Dockerfile -t fduarte42/docker-php:$V .
    docker build --no-cache -f Dockerfile-debug -t fduarte42/docker-php:$V-debug .
    docker build --no-cache -f Dockerfile-intl -t fduarte42/docker-php:$V-intl .
    docker build --no-cache -f Dockerfile-intl-debug -t fduarte42/docker-php:$V-intl-debug .
    cd ..
done

exit 0