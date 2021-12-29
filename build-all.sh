#!/usr/bin/env bash
set -e

BASE_IMAGENAME=registry.gitlab.com/it-cocktail/docker-php
PLATFORMS=linux/amd64,linux/arm64

cd build
VERSIONS="7.2 7.4 8.0 8.1"

for V in $VERSIONS; do
    # normal version
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile -t $BASE_IMAGENAME:$V .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-debug -t $BASE_IMAGENAME:$V-debug .

    if [[ $V =~ (7\.2|7\.4) ]]; then
        # ioncube
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-ioncube_loader -t $BASE_IMAGENAME:$V-ioncube_loader .
    fi

    if [[ $V =~ (7\.2|7\.4|8\.0) ]]; then
        # sourceguardian
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-sourceguardian -t $BASE_IMAGENAME:$V-sourceguardian .
    fi

    if [[ $V =~ (7\.2|7\.4|8\.0) ]]; then
        # chartdirector
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-chartdirector -t $BASE_IMAGENAME:$V-chartdirector .
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-chartdirector-debug -t $BASE_IMAGENAME:$V-chartdirector-debug .
    fi

    # oracle
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-oci -t $BASE_IMAGENAME:$V-oci .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-oci-debug -t $BASE_IMAGENAME:$V-oci-debug .

    # sqlsrv
    #docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-sqlsrv -t $BASE_IMAGENAME:$V-sqlsrv .
    #docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V -f Dockerfile-sqlsrv-debug -t $BASE_IMAGENAME:$V-sqlsrv-debug .

done

cd ..
