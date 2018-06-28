#!/usr/bin/env bash
set -e

VERSIONS="5.3 5.5 5.6 7.0 7.1 7.2"

for V in $VERSIONS; do
    docker push fduarte42/docker-php:$V
    docker push fduarte42/docker-php:$V-debug
done

EXTRA_VERSIONS="7.2"

for V in $EXTRA_VERSIONS; do
    docker push fduarte42/docker-php:$V-sqlsrv
    docker push fduarte42/docker-php:$V-sqlsrv-debug
    docker push fduarte42/docker-php:$V-oci
    docker push fduarte42/docker-php:$V-oci-debug
done
