#!/usr/bin/env bash
set -e

if [ "$GITHUB_ACTIONS" = "true" ]; then
  echo "Running inside GitHub Actions"
  BASE_IMAGENAME=ghcr.io/fduarte42/docker-php
else
  echo "Running locally"
  BASE_IMAGENAME=fduarte42/docker-php
fi

function tag_args() {
  local TAG="$1"

  if [ "$GITHUB_ACTIONS" = "true" ]; then
    echo "-t ghcr.io/fduarte42/docker-php:$TAG -t docker.io/fduarte42/docker-php:$TAG"
  else
    echo "-t fduarte42/docker-php:$TAG"
  fi
}

PLATFORMS=linux/amd64,linux/arm64


if [ "$#" -gt 0 ]; then
  VERSIONS="$*"
else
  VERSIONS="8.2 8.3 8.4 8.5"
fi

cd build

for V in $VERSIONS; do
    if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
      # slim version
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-slim $(tag_args "$V-slim") .
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-debug $(tag_args "$V-slim-debug") .

      # slim oracle version
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-oci $(tag_args "$V-slim-oci") .
      docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim-debug" -f Dockerfile-oci $(tag_args "$V-slim-oci-debug") .
    fi

    # normal version
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile $(tag_args "$V") .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-debug $(tag_args "$V-debug") .

    # oracle
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-oci $(tag_args "$V-oci") .
    docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-oci $(tag_args "$V-oci-debug") .

    if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
        # sourceguardian
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-sourceguardian $(tag_args "$V-sourceguardian") .

        # sourceguardian with oracle
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-oci" -f Dockerfile-sourceguardian $(tag_args "$V-oci-sourceguardian") .
    fi

    if [[ $V =~ (7\.4) ]]; then
        # chartdirector
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-chartdirector $(tag_args "$V-chartdirector") .
        docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-chartdirector $(tag_args "$V-chartdirector-debug") .
    fi
done

cd ..
