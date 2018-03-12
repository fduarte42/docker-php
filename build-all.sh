#!/usr/bin/env bash
set -e

VERSIONS="5.3 5.5 5.6 7.0 7.1 7.2"

for V in $VERSIONS; do
    docker build --pull --no-cache -f $V/Dockerfile -t fduarte42/docker-php:$V $V
    docker build --no-cache -f $V/Dockerfile-debug -t fduarte42/docker-php:$V-debug $V
done