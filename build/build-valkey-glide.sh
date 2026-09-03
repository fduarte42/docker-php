#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
export TERM=linux

# valkey glide has no sury package, so PIE builds it from the upstream source release. That compiles
# glide's rust ffi core, so this runs in its own throwaway build stage: nothing installed here reaches
# the final image and only /out/valkey_glide.so is copied out of it.
mkdir -p /out

# no valkey_glide build for other versions - an empty /out is what keeps their image build working
if [[ ! $PHP_VERSION =~ (8\.2|8\.3|8\.4|8\.5) ]]; then
  echo "valkey_glide: no build for PHP ${PHP_VERSION}, leaving /out empty"
  exit 0
fi

# bump these together
VALKEY_GLIDE_VERSION=1.1.2
# the rustup pin must satisfy glide's locked aws sdk crates (>=1.91.1 as of extension 1.1.2)
VALKEY_GLIDE_RUST_VERSION=1.98.0
PIE_VERSION=1.4.10
PIE_SHA256=b88792235c8e80be568436d4cb043b49fd1869c89b64e83d23e2882ae19d70a8
CBINDGEN_VERSION=0.29.4

# php APT repo (mirror) - must be the same source as build.sh so the .so matches the final image's
# php build. node/yarn/contrib are not needed here.
apt-get update
apt-get install -y apt-transport-https lsb-release ca-certificates curl gnupg
curl -fsSL https://mirrors.dotsrc.org/deb.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/deb.sury.org.gpg
echo "deb [signed-by=/usr/share/keyrings/deb.sury.org.gpg] https://mirrors.dotsrc.org/deb.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt-get update

# php to run pie.phar with (curl/mbstring/xml/zip are what it needs to fetch and unpack the release)
# plus the toolchain. python3 is required by the extension's config.m4.
apt-get install -y \
  php${PHP_VERSION}-cli \
  php${PHP_VERSION}-dev \
  php${PHP_VERSION}-curl \
  php${PHP_VERSION}-mbstring \
  php${PHP_VERSION}-xml \
  php${PHP_VERSION}-zip \
  build-essential \
  cmake \
  git \
  libffi-dev \
  libprotobuf-c-dev \
  libssl-dev \
  pkg-config \
  protobuf-c-compiler \
  protobuf-compiler \
  python3 \
  unzip

curl -fsSL -o /tmp/pie.phar "https://github.com/php/pie/releases/download/${PIE_VERSION}/pie.phar"
echo "${PIE_SHA256}  /tmp/pie.phar" | sha256sum -c -

curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal --default-toolchain ${VALKEY_GLIDE_RUST_VERSION}
export PATH="/root/.cargo/bin:${PATH}"

# cbindgen generates the ffi header - the trixie package (0.27) is too old, it does not
# understand edition 2024 `#[unsafe(no_mangle)]` and silently emits an empty header
if [ "$TARGETARCH" = "arm64" ]; then
  CBINDGEN_ASSET=cbindgen-ubuntu22.04-aarch64
  CBINDGEN_SHA256=1838dfc7ddfb7e941556505fa6eebc5c28553eb03118980262c760594e240bdb
else
  CBINDGEN_ASSET=cbindgen-ubuntu22.04
  CBINDGEN_SHA256=27ac237e2ad3ffaffc8ecce0c03e3caa1d1b09e691906c3cb0967367ff6d783d
fi
curl -fsSL -o /usr/local/bin/cbindgen \
  "https://github.com/mozilla/cbindgen/releases/download/${CBINDGEN_VERSION}/${CBINDGEN_ASSET}"
echo "${CBINDGEN_SHA256}  /usr/local/bin/cbindgen" | sha256sum -c -
chmod 755 /usr/local/bin/cbindgen

# glide ships lto="fat" + codegen-units=1; relax it, this also builds under qemu
export CARGO_PROFILE_RELEASE_LTO=false
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=$(nproc)
export CARGO_PROFILE_RELEASE_DEBUG=false
# needs git installed above
export CARGO_NET_GIT_FETCH_WITH_CLI=true

# PIE installs only the extension; the package's helper PHP classes are deliberately not shipped
# (consumers `composer require valkey-io/valkey-glide-php`)
php${PHP_VERSION} /tmp/pie.phar install "valkey-io/valkey-glide-php:${VALKEY_GLIDE_VERSION}" \
  --with-php-config=/usr/bin/php-config${PHP_VERSION} \
  --skip-enable-extension \
  --no-build-tools-check \
  --no-system-dependencies-check \
  --no-interaction

cp "$(/usr/bin/php-config${PHP_VERSION} --extension-dir)/valkey_glide.so" /out/valkey_glide.so

# fail the build here if the extension does not load
php${PHP_VERSION} -d extension=/out/valkey_glide.so -m | grep -qx valkey_glide

exit 0
