#!/usr/bin/env bash
set -e

#BASE_IMAGENAME=registry.gitlab.com/it-cocktail/docker-php
BASE_IMAGENAME=fduarte42/docker-php
PLATFORMS=linux/amd64,linux/arm64

cd build
#VERSIONS="7.4 8.0 8.1 8.2 8.3"
VERSIONS="7.4 8.2 8.3"

for V in $VERSIONS; do
    if [[ $V =~ (8\.2|8\.3|8\.4) ]]; then
      # slim version
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-slim -t "$BASE_IMAGENAME:$V-slim" .
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-debug -t "$BASE_IMAGENAME:$V-slim-debug" .

      # slim oracle version
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-oci -t "$BASE_IMAGENAME:$V-slim-oci" .
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim-debug" -f Dockerfile-oci -t "$BASE_IMAGENAME:$V-slim-oci-debug" .
    fi

    # normal version
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile -t "$BASE_IMAGENAME:$V" .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-debug -t "$BASE_IMAGENAME:$V-debug" .

    # oracle
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-oci -t "$BASE_IMAGENAME:$V-oci" .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-oci -t "$BASE_IMAGENAME:$V-oci-debug" .

    if [[ $V =~ (8\.2|8\.3) ]]; then
        # sourceguardian
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-sourceguardian -t "$BASE_IMAGENAME:$V-sourceguardian" .

        # sourceguardian with oracle
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-oci" -f Dockerfile-sourceguardian -t "$BASE_IMAGENAME:$V-oci-sourceguardian" .
    fi

    if [[ $V =~ (7\.4) ]]; then
        # chartdirector
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-chartdirector -t "$BASE_IMAGENAME:$V-chartdirector" .
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-chartdirector -t "$BASE_IMAGENAME:$V-chartdirector-debug" .
    fi
done

cd ..
