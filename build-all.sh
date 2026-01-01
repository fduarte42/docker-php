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
BUILD_SLIM=true
BUILD_NONE_SLIM=true
LOCAL_BUILD=false

function build_args() {
  if [ "$LOCAL_BUILD" = true ]; then
    echo "--load --pull --no-cache"
  else
    echo "--push --pull --no-cache"
  fi
}

while getopts "p:slnh" opt; do
  case $opt in
    p)
      PLATFORMS="$OPTARG"
      ;;
    s)
      BUILD_SLIM=true
      BUILD_NONE_SLIM=false
      ;;
    n)
      BUILD_SLIM=false
      BUILD_NONE_SLIM=true
      ;;
    l)
      LOCAL_BUILD=true
      ;;
    h)
      echo "Usage: $0 [OPTIONS] [PHP_VERSIONS...]"
      echo ""
      echo "OPTIONS:"
      echo "  -p PLATFORMS    Comma-separated list of platforms (e.g., linux/amd64,linux/arm64)"
      echo "  -s              Build only slim versions"
      echo "  -n              Skip slim versions"
      echo "  -l              Local build only (do not push)"
      echo "  -h              Show this help message"
      echo ""
      echo "EXAMPLES:"
      echo "  $0 8.4                           # Build 8.4 for default platforms"
      echo "  $0 -p linux/amd64 8.4            # Build 8.4 for amd64 only"
      echo "  $0 -s 8.4                        # Build only slim variant of 8.4"
      echo "  $0 -n 8.4                        # Build 8.4 skipping slim versions"
      echo "  $0 -l 8.4                        # Build 8.4 locally without pushing"
      echo "  $0 -p linux/arm64 -s 8.3 8.4    # Build slim variants of 8.3 and 8.4 for arm64 only"
      exit 0
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
  VERSIONS="$*"
else
  VERSIONS="8.2 8.3 8.4 8.5"
fi

cd build

for V in $VERSIONS; do
    if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
      if [ "$BUILD_SLIM" = true ]; then
        # slim version
        docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-slim $(tag_args "$V-slim") .
        docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-debug $(tag_args "$V-slim-debug") .

        # slim oracle version
        docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-oci $(tag_args "$V-slim-oci") .
        docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim-debug" -f Dockerfile-oci $(tag_args "$V-slim-oci-debug") .

        if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
          # sourceguardian
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim" -f Dockerfile-sourceguardian $(tag_args "$V-slim-sourceguardian") .

          # sourceguardian with oracle
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-slim-oci" -f Dockerfile-sourceguardian $(tag_args "$V-slim-oci-sourceguardian") .
        fi
      fi
    fi

    if [ "$BUILD_NONE_SLIM" = true ]; then
      # normal version
      docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile $(tag_args "$V") .
      docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-debug $(tag_args "$V-debug") .

      # oracle
      docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-oci $(tag_args "$V-oci") .
      docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-oci $(tag_args "$V-oci-debug") .

      if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
          # sourceguardian
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-sourceguardian $(tag_args "$V-sourceguardian") .

          # sourceguardian with oracle
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-oci" -f Dockerfile-sourceguardian $(tag_args "$V-oci-sourceguardian") .
      fi

      if [[ $V =~ (7\.4) ]]; then
          # chartdirector
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" -f Dockerfile-chartdirector $(tag_args "$V-chartdirector") .
          docker buildx build --platform $PLATFORMS $(build_args) --build-arg BASE_IMAGENAME=$BASE_IMAGENAME --build-arg PHP_VERSION="$V" --build-arg FLAVOR="-debug" -f Dockerfile-chartdirector $(tag_args "$V-chartdirector-debug") .
      fi
    fi
done

cd ..
