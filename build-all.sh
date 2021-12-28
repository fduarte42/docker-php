#!/usr/bin/env bash
set -e

cd build
VERSIONS="7.2 7.4 8.0 8.1"

for V in $VERSIONS; do
    # normal version
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile -t fduarte42/docker-php:$V .
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-debug -t fduarte42/docker-php:$V-debug .

    if [[ $V =~ (7\.2|7\.4) ]]; then
        # ioncube
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-ioncube_loader -t fduarte42/docker-php:$V-ioncube_loader .
    fi

    if [[ $V =~ (7\.2|7\.4|8\.0) ]]; then
        # sourceguardian
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-sourceguardian -t fduarte42/docker-php:$V-sourceguardian .
    fi

    if [[ $V =~ (7\.2|7\.4|8\.0) ]]; then
        # chartdirector
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-chartdirector -t fduarte42/docker-php:$V-chartdirector .
        docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-chartdirector-debug -t fduarte42/docker-php:$V-chartdirector-debug .
    fi

    # oracle
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-oci -t fduarte42/docker-php:$V-oci .
    docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-oci-debug -t fduarte42/docker-php:$V-oci-debug .

    # sqlsrv
    #docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-sqlsrv -t fduarte42/docker-php:$V-sqlsrv .
    #docker buildx build --platform linux/amd64,linux/arm64 --push --pull --no-cache --build-arg PHP_VERSION=$V -f Dockerfile-sqlsrv-debug -t fduarte42/docker-php:$V-sqlsrv-debug .

done

cd ..
