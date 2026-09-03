#!/usr/bin/env bash
set -e

# informational, on stderr so it never pollutes the tag list that -L writes to stdout
if [ "$GITHUB_ACTIONS" = "true" ]; then
  echo "Running inside GitHub Actions" >&2
  BASE_IMAGENAME=ghcr.io/fduarte42/docker-php
else
  echo "Running locally" >&2
  BASE_IMAGENAME=fduarte42/docker-php
fi

PLATFORMS=linux/amd64,linux/arm64
BUILD_SLIM=true
BUILD_NONE_SLIM=true
LOCAL_BUILD=false
# appended to every tag produced and to the tag every derived flavor resolves its FROM against.
# CI builds one platform per runner into "-amd64"/"-arm64" tags and merges them afterwards.
TAG_SUFFIX=""
LIST_ONLY=false

function tag_args() {
  local TAG="$1$TAG_SUFFIX"

  if [ "$GITHUB_ACTIONS" = "true" ]; then
    echo "-t ghcr.io/fduarte42/docker-php:$TAG -t docker.io/fduarte42/docker-php:$TAG"
  else
    echo "-t fduarte42/docker-php:$TAG"
  fi
}

function build_args() {
  if [ "$LOCAL_BUILD" = true ]; then
    echo "--load --pull --no-cache"
  else
    echo "--push --pull"
  fi
}

# build <tag> <dockerfile> [extra docker buildx args...]
# $TAG_SUFFIX is applied to the tag; $V is the version currently being built.
function build() {
  local TAG="$1"; shift
  local DOCKERFILE="$1"; shift

  if [ "$LIST_ONLY" = true ]; then
    # unsuffixed on purpose - consumers (the CI merge job) append the arch suffix themselves
    echo "$TAG"
    return 0
  fi

  # The base/slim images compile valkey_glide in a separate valkey-glide-builder stage. Cache just
  # that stage in the registry so an unchanged build-valkey-glide.sh does not recompile the rust
  # core on every run. Deliberately NOT a whole-image cache: that would freeze the build.sh apt
  # layer and defeat the point of rebuilding weekly. The ref is shared by the slim and non-slim
  # jobs on purpose - the builder stage is identical in both Dockerfiles, so either may write it.
  local CACHE_ARGS=""
  if [ "$GITHUB_ACTIONS" = "true" ] && [[ $DOCKERFILE =~ ^Dockerfile(-slim)?$ ]]; then
    local CACHE_REF="ghcr.io/fduarte42/docker-php:cache-valkey-glide-${V}${TAG_SUFFIX}"
    # --pull must match the main build below, otherwise the two can resolve different
    # debian:trixie-slim digests and the builder stage misses the cache it just wrote
    docker buildx build --platform $PLATFORMS --target valkey-glide-builder --pull \
      --build-arg PHP_VERSION="$V" \
      --cache-from type=registry,ref=$CACHE_REF \
      --cache-to type=registry,ref=$CACHE_REF,mode=max \
      --output type=cacheonly \
      -f "$DOCKERFILE" .
    CACHE_ARGS="--cache-from type=registry,ref=$CACHE_REF"
  fi

  docker buildx build --platform $PLATFORMS $(build_args) $CACHE_ARGS \
    --build-arg BASE_IMAGENAME=$BASE_IMAGENAME \
    --build-arg PHP_VERSION="$V" \
    --build-arg TAG_SUFFIX="$TAG_SUFFIX" \
    "$@" -f "$DOCKERFILE" $(tag_args "$TAG") .
}

while getopts "p:t:slnLh" opt; do
  case $opt in
    p)
      PLATFORMS="$OPTARG"
      ;;
    t)
      TAG_SUFFIX="$OPTARG"
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
    L)
      LIST_ONLY=true
      ;;
    h)
      echo "Usage: $0 [OPTIONS] [PHP_VERSIONS...]"
      echo ""
      echo "OPTIONS:"
      echo "  -p PLATFORMS    Comma-separated list of platforms (e.g., linux/amd64,linux/arm64)"
      echo "  -t SUFFIX       Append SUFFIX to every tag built and to every FROM it resolves"
      echo "  -s              Build only slim versions"
      echo "  -n              Skip slim versions"
      echo "  -l              Local build only (do not push)"
      echo "  -L              List the tags that would be built (unsuffixed) and exit"
      echo "  -h              Show this help message"
      echo ""
      echo "EXAMPLES:"
      echo "  $0 8.4                           # Build 8.4 for default platforms"
      echo "  $0 -p linux/amd64 8.4            # Build 8.4 for amd64 only"
      echo "  $0 -s 8.4                        # Build only slim variant of 8.4"
      echo "  $0 -n 8.4                        # Build 8.4 skipping slim versions"
      echo "  $0 -l 8.4                        # Build 8.4 locally without pushing"
      echo "  $0 -p linux/arm64 -s 8.3 8.4    # Build slim variants of 8.3 and 8.4 for arm64 only"
      echo "  $0 -p linux/arm64 -t -arm64 8.4  # Build 8.4 arm64 only, into ...:8.4-arm64 etc"
      echo "  $0 -L -n 8.4                     # Print the non-slim tags for 8.4, build nothing"
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
        build "$V-slim"                     Dockerfile-slim
        build "$V-slim-debug"               Dockerfile-debug --build-arg FLAVOR="-slim"

        # slim oracle version
        build "$V-slim-oci"                 Dockerfile-oci --build-arg FLAVOR="-slim"
        build "$V-slim-oci-debug"           Dockerfile-oci --build-arg FLAVOR="-slim-debug"

        if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
          # sourceguardian
          build "$V-slim-sourceguardian"     Dockerfile-sourceguardian --build-arg FLAVOR="-slim"

          # sourceguardian with oracle
          build "$V-slim-oci-sourceguardian" Dockerfile-sourceguardian --build-arg FLAVOR="-slim-oci"
        fi
      fi
    fi

    if [ "$BUILD_NONE_SLIM" = true ]; then
      # normal version
      build "$V"                            Dockerfile
      build "$V-debug"                      Dockerfile-debug

      # oracle
      build "$V-oci"                        Dockerfile-oci
      build "$V-oci-debug"                  Dockerfile-oci --build-arg FLAVOR="-debug"

      if [[ $V =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
          # sourceguardian
          build "$V-sourceguardian"          Dockerfile-sourceguardian

          # sourceguardian with oracle
          build "$V-oci-sourceguardian"      Dockerfile-sourceguardian --build-arg FLAVOR="-oci"
      fi

      if [[ $V =~ (7\.4) ]]; then
          # chartdirector
          build "$V-chartdirector"           Dockerfile-chartdirector
          build "$V-chartdirector-debug"     Dockerfile-chartdirector --build-arg FLAVOR="-debug"
      fi
    fi
done

cd ..
