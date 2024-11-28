#!/usr/bin/env bash
set -e

#BASE_IMAGENAME=registry.gitlab.com/it-cocktail/docker-php
BASE_IMAGENAME=fduarte42/docker-php
PLATFORMS=linux/amd64,linux/arm64

cd build

while getopts "v:f:d" OPTION; do
  FLAVOR=""
  BUILD_DEBUG=0
  case "${OPTION}" in
    v)
        V=${OPTARG}
        ;;
    f)
        FLAVOR=${OPTARG}
        ;;
    d)
        BUILD_DEBUG=1
        ;;
    :)
        critical "Option -${OPTARG} requires an argument."
        quit
        ;;
    ?)
        critical "Invalid option: -${OPTARG}."
        quit
        ;;
  esac
done

BUILD_COMMAND="docker buildx build --platform $PLATFORMS --push --pull --no-cache --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION=$V"
case "${FLAVOR}" in
  "")
    $BUILD_COMMAND -f Dockerfile -t $BASE_IMAGENAME:$V .
    if [ "${BUILD_DEBUG}" == 1 ]; then
      $BUILD_COMMAND -f Dockerfile-debug -t $BASE_IMAGENAME:$V-debug .
    fi
    ;;
  chartdirector)
    $BUILD_COMMAND -f Dockerfile-chartdirector -t $BASE_IMAGENAME:$V-chartdirector .
    if [ "${BUILD_DEBUG}" == 1 ]; then
      $BUILD_COMMAND --build-arg FLAVOR="-debug" -f Dockerfile-chartdirector -t $BASE_IMAGENAME:$V-chartdirector-debug .
    fi
    ;;
  oci)
    $BUILD_COMMAND -f Dockerfile-oci -t $BASE_IMAGENAME:$V-oci .
    if [ "${BUILD_DEBUG}" == 1 ]; then
      $BUILD_COMMAND --build-arg FLAVOR="-debug" -f Dockerfile-oci -t $BASE_IMAGENAME:$V-oci-debug .
    fi
    ;;
  sourceguardian)
    $BUILD_COMMAND --build-arg FLAVOR="" -f Dockerfile-sourceguardian -t $BASE_IMAGENAME:$V-sourceguardian .
    ;;
  sourceguardian-oci)
    $BUILD_COMMAND --build-arg FLAVOR="-oci" -f Dockerfile-sourceguardian -t $BASE_IMAGENAME:$V-oci-sourceguardian .
    ;;
  slim)
    $BUILD_COMMAND -f Dockerfile-slim -t $BASE_IMAGENAME:$V-slim .
    if [ "${BUILD_DEBUG}" == 1 ]; then
      $BUILD_COMMAND --build-arg FLAVOR="-slim-debug" -f Dockerfile-oci -t $BASE_IMAGENAME:$V-slim-oci-debug .
    fi
    ;;
  slim-oci)
    $BUILD_COMMAND --build-arg FLAVOR="-slim" -f Dockerfile-oci -t $BASE_IMAGENAME:$V-slim-oci .
    if [ "${BUILD_DEBUG}" == 1 ]; then
      $BUILD_COMMAND --build-arg FLAVOR="-slim" -f Dockerfile-debug -t $BASE_IMAGENAME:$V-debug .
    fi
    ;;

esac

cd ..
