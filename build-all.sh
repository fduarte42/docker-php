#!/usr/bin/env bash
set -e

#VERSIONS="7.2 7.4 8.0 8.1"
VERSIONS="7.2 7.4"

for V in $VERSIONS; do
    cd $V

    # normal version
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile -t fduarte42/docker-php:$V .
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-debug -t fduarte42/docker-php:$V-debug .

    if [[ $V =~ (7\.2|7\.4) ]]; then
        # ioncube
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-ioncube_loader -t fduarte42/docker-php:$V-ioncube_loader .
    fi

    if [[ $V =~ (7\.2|7\.4|8\.0) ]]; then
        # chartdirector
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-chartdirector -t fduarte42/docker-php:$V-chartdirector .
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-chartdirector-debug -t fduarte42/docker-php:$V-chartdirector-debug .
    fi

    # oracle
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-oci -t fduarte42/docker-php:$V-oci .
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-oci-debug -t fduarte42/docker-php:$V-oci-debug .

    # sqlsrv
    #docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-sqlsrv -t fduarte42/docker-php:$V-sqlsrv .
    #docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache -f Dockerfile-sqlsrv-debug -t fduarte42/docker-php:$V-sqlsrv-debug .

    cd ..
done
