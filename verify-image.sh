#!/usr/bin/env bash
# verify-image.sh <image-ref> <tag>
#
# Checks a built image against the runtime contract its consumers rely on (CLAUDE.md, "Runtime contract
# of the images"). <tag> is the unsuffixed tag name, e.g. 8.4-slim-oci-debug: the PHP version and the
# flavors to expect are read from it, valkey_glide from VERSION_TABLE. <image-ref> is what to run, e.g.
# fduarte42/docker-php:8.4-slim-oci-debug or ghcr.io/fduarte42/docker-php:8.4-slim-oci-debug-arm64.
#
# Prints one line per check and exits non-zero if any failed. Runs the image natively, so it can only
# check images of the host's architecture. Called by build-all.sh -V after every tag it builds.
set -u

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <image-ref> <tag>   e.g. $0 fduarte42/docker-php:8.4-slim 8.4-slim" >&2
  exit 2
fi
IMAGE=$1
TAG=$2

source "$(dirname "$0")/versions.sh"

PV=${TAG%%-*}
if ! known_versions | grep -qxF "$PV"; then
  echo "verify-image: '$TAG' does not start with a known PHP version ($(known_versions | xargs))" >&2
  exit 2
fi

VARIANT=full DEBUG=no
MODULES="apcu bcmath bz2 curl gd igbinary imagick imap intl ldap mbstring memcached msgpack mysqli
         pdo_mysql pdo_pgsql pdo_sqlite pgsql raphf redis soap sqlite3 ssh2 xml xsl zip"
for F in $(tr - ' ' <<< "${TAG#"$PV"}"); do
  case "$F" in
    slim)           VARIANT=slim ;;
    debug)          DEBUG=yes; MODULES="$MODULES xdebug" ;;
    oci)            MODULES="$MODULES oci8" ;;
    sourceguardian) MODULES="$MODULES SourceGuardian" ;;
    # php -m lists it under its display name; spaces are restored below
    chartdirector)  MODULES="$MODULES ChartDirector_PHP_API" ;;
    *) echo "verify-image: unknown flavor '$F' in tag '$TAG'" >&2; exit 2 ;;
  esac
done
# the version deltas of build.sh
if [[ $PV =~ ^(5\.6|7\.4)$ ]]; then
  MODULES="$MODULES apc propro"
fi
if [[ ! $PV =~ ^(5\.6)$ ]]; then
  MODULES="$MODULES decimal http"
fi
if has "$PV" valkey-glide; then
  MODULES="$MODULES valkey_glide"
fi
MODULES="$MODULES Zend_OPcache"

FAILED=0
ok()   { echo "  ok    $*"; }
fail() { echo "  FAIL  $*"; FAILED=$((FAILED + 1)); }
expect() { # expect <description> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1: expected '$2', got '$3'"; fi
}

echo "verify $IMAGE as $TAG (PHP $PV, $VARIANT, debug=$DEBUG)"

if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
  docker pull -q "$IMAGE" > /dev/null || { fail "pull $IMAGE"; exit 1; }
fi

# the probes run the image, which only means something on its native architecture
HOST_ARCH=$(docker info -f '{{.Architecture}}' | sed 's/^x86_64$/amd64/; s/^aarch64$/arm64/')
IMAGE_ARCH=$(docker image inspect -f '{{.Architecture}}' "$IMAGE")
if [ "$IMAGE_ARCH" != "$HOST_ARCH" ]; then
  echo "verify-image: $IMAGE is $IMAGE_ARCH, this host is $HOST_ARCH - verify it on a $IMAGE_ARCH host" >&2
  exit 2
fi

# --- image config -------------------------------------------------------------------------------
expect "WORKDIR"    /var/www/html "$(docker image inspect -f '{{.Config.WorkingDir}}' "$IMAGE")"
expect "EXPOSE"     "map[80/tcp:{}]" "$(docker image inspect -f '{{.Config.ExposedPorts}}' "$IMAGE")"
expect "ENTRYPOINT" "[/usr/local/bin/docker-php-entrypoint]" "$(docker image inspect -f '{{.Config.Entrypoint}}' "$IMAGE")"
expect "CMD"        "[/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf]" \
                    "$(docker image inspect -f '{{.Config.Cmd}}' "$IMAGE")"

# --- one-shot probes inside the image -----------------------------------------------------------
# The probe prints its own ok/FAIL lines; FAIL lines are counted here.
PROBE_OUT=$(docker run --rm -i --entrypoint bash \
  -e PV="$PV" -e VARIANT="$VARIANT" -e DEBUG="$DEBUG" -e MODULES="$MODULES" \
  "$IMAGE" -s 2>&1 <<'PROBE'
ok()   { echo "  ok    $*"; }
fail() { echo "  FAIL  $*"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else fail "$1: expected '$2', got '$3'"; fi; }
has_cmd() { command -v "$1" > /dev/null 2>&1; }

MISSING=""
LOADED=$(php -m)
for M in $MODULES; do
  grep -qxF "${M//_/ }" <<< "$LOADED" || grep -qxF "$M" <<< "$LOADED" || MISSING="$MISSING ${M//_/ }"
done
expect "cli modules (missing)" "" "${MISSING# }"

php_bool() { php -r "echo filter_var(ini_get('$1'), FILTER_VALIDATE_BOOLEAN) ? 'on' : 'off';"; }
if [ "$DEBUG" = yes ]; then expect "cli display_errors" on "$(php_bool display_errors)"
else                        expect "cli display_errors" off "$(php_bool display_errors)"; fi
expect "cli log_errors" on "$(php_bool log_errors)"

expect "env DOCUMENT_ROOT" / "${DOCUMENT_ROOT-unset}"
expect "env PHP_GC_MAX_LIFETIME" 1440 "${PHP_GC_MAX_LIFETIME-unset}"
expect "env COMPOSER_HOME" /composer "${COMPOSER_HOME-unset}"
expect "env COMPOSER_ALLOW_SUPERUSER" 1 "${COMPOSER_ALLOW_SUPERUSER-unset}"
case ":$PATH:" in *:/composer/vendor/bin:*) ok "PATH has /composer/vendor/bin" ;;
                  *) fail "PATH has /composer/vendor/bin: $PATH" ;; esac

if [ "$VARIANT" = full ]; then
  expect "env PUPPETEER_EXECUTABLE_PATH" /usr/bin/chromium "${PUPPETEER_EXECUTABLE_PATH-unset}"
  expect "env PUPPETEER_SKIP_CHROMIUM_DOWNLOAD" true "${PUPPETEER_SKIP_CHROMIUM_DOWNLOAD-unset}"
  has_cmd chromium    && ok "chromium present"    || fail "chromium missing"
  has_cmd wkhtmltopdf && ok "wkhtmltopdf present" || fail "wkhtmltopdf missing"
else
  expect "env PUPPETEER_EXECUTABLE_PATH" unset "${PUPPETEER_EXECUTABLE_PATH-unset}"
  has_cmd chromium    && fail "chromium present in slim"    || ok "chromium absent"
  has_cmd wkhtmltopdf && fail "wkhtmltopdf present in slim" || ok "wkhtmltopdf absent"
fi

# deliberate security choice (ImageMagick attack surface)
if dpkg -s ghostscript > /dev/null 2>&1 || has_cmd gs; then fail "ghostscript present"; else ok "ghostscript absent"; fi

expect "/etc/timezone" Europe/Berlin "$(cat /etc/timezone)"
expect "/etc/localtime" /usr/share/zoneinfo/Europe/Berlin "$(readlink -f /etc/localtime)"
expect "php date.timezone" Europe/Berlin "$(php -r 'echo date_default_timezone_get();')"
MISSING=""
for L in en_US en_GB fr_FR es_ES pt_PT de_DE; do
  locale -a | grep -qx "$L.utf8" || MISSING="$MISSING $L"
done
expect "locales (missing)" "" "${MISSING# }"

expect "zzz-custom.ini hook" "/etc/php/$PV/mods-available/zzz-custom.ini" \
  "$(readlink -f /usr/local/etc/php/conf.d/zzz-custom.ini)"
for SAPI in cli fpm; do
  expect "zzz-custom.ini in $SAPI/conf.d" "/etc/php/$PV/mods-available/zzz-custom.ini" \
    "$(readlink -f /etc/php/$PV/$SAPI/conf.d/zzz-custom.ini)"
done

expect "sudoers for www-data" \
  "www-data ALL = (root) NOPASSWD: /etc/init.d/apache2 reload|www-data ALL = (root) NOPASSWD: /usr/local/bin/php-fpm-reload.sh" \
  "$(cat /etc/sudoers.d/* | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | sort | paste -sd '|')"
expect "/var/www owner" www-data:www-data "$(stat -c %U:%G /var/www)"

MISSING=""
TOOLS="composer phpcs"
case "$PV" in
  5.6) ;;
  8.6) TOOLS="$TOOLS psalm" ;;  # composer-require-checker has no release allowing 8.6 yet
  *)   TOOLS="$TOOLS psalm composer-require-checker" ;;
esac
for T in $TOOLS; do has_cmd "$T" || MISSING="$MISSING $T"; done
expect "composer tools (missing)" "" "${MISSING# }"

# pdftk shim: a hand-written 2-page PDF (qpdf rebuilds its xref), then cat + burst
cd "$(mktemp -d)"
printf '%%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R 4 0 R]/Count 2>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\n4 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]>>endobj\ntrailer<</Root 1 0 R>>\n%%%%EOF\n' > raw.pdf
qpdf raw.pdf two.pdf > /dev/null 2>&1
pdftk two.pdf cat 2 output one.pdf > /dev/null 2>&1
expect "pdftk cat" 1 "$(pdftk one.pdf dump_data 2>/dev/null | awk '/^NumberOfPages:/ { print $2 }')"
pdftk two.pdf burst output 'pg_%02d.pdf' > /dev/null 2>&1
expect "pdftk burst" 2 "$(ls pg_*.pdf 2>/dev/null | wc -l)"
PROBE
)
echo "$PROBE_OUT"
FAILED=$((FAILED + $(grep -c '^  FAIL' <<< "$PROBE_OUT")))

# --- www-data remap (docker-php-entrypoint) -----------------------------------------------------
expect "WWW_DATA_UID/GID remap" "4321:4321 4321:4321" \
  "$(docker run --rm -e WWW_DATA_UID=4321 -e WWW_DATA_GID=4321 "$IMAGE" \
       bash -c 'echo "$(id -u www-data):$(id -g www-data) $(stat -c %u:%g /var/www)"' 2>/dev/null | tail -n 1)"

# --- live boot: the image's own CMD, a request through apache -> php-fpm ------------------------
# The consumer ini hook is exercised the way consumers use it: a file mounted over zzz-custom.ini.
INI_DIR=$(mktemp -d)
echo "memory_limit=321M" > "$INI_DIR/zzz-custom.ini"
chmod 755 "$INI_DIR"; chmod 644 "$INI_DIR/zzz-custom.ini"
CID=$(docker run -d -v "$INI_DIR/zzz-custom.ini:/usr/local/etc/php/conf.d/zzz-custom.ini:ro,z" "$IMAGE")
trap 'docker rm -f "$CID" > /dev/null 2>&1; rm -rf "$INI_DIR"' EXIT

docker exec -i "$CID" bash -c 'mkdir -p /var/www/html/__verify_dir && cat > /var/www/html/__verify.php' <<'PHP'
<?php
echo php_sapi_name(), "\n";
echo ini_get('memory_limit'), "\n";
echo filter_var(ini_get('display_errors'), FILTER_VALIDATE_BOOLEAN) ? 'on' : 'off', "\n";
echo implode(',', get_loaded_extensions()), "\n";
PHP

in_ct() { docker exec "$CID" "$@" 2>/dev/null; }
CODE=000
for _ in $(seq 60); do
  CODE=$(in_ct curl -s -o /dev/null -w '%{http_code}' http://localhost/__verify.php)
  [ "$CODE" = 200 ] && break
  sleep 1
done
expect "boot: GET /__verify.php" 200 "$CODE"

if [ "$CODE" = 200 ]; then
  PAGE=$(in_ct curl -s http://localhost/__verify.php)
  expect "fpm: SAPI" fpm-fcgi "$(sed -n 1p <<< "$PAGE")"
  expect "fpm: zzz-custom.ini memory_limit" 321M "$(sed -n 2p <<< "$PAGE")"
  if [ "$DEBUG" = yes ]; then expect "fpm: display_errors" on "$(sed -n 3p <<< "$PAGE")"
  else                        expect "fpm: display_errors" off "$(sed -n 3p <<< "$PAGE")"; fi
  MISSING=""
  for M in $MODULES; do
    tr , '\n' <<< "$(sed -n 4p <<< "$PAGE")" | grep -qxF "${M//_/ }" \
      || tr , '\n' <<< "$(sed -n 4p <<< "$PAGE")" | grep -qxF "$M" || MISSING="$MISSING ${M//_/ }"
  done
  expect "fpm modules (missing)" "" "${MISSING# }"
  expect "cli: zzz-custom.ini memory_limit" 321M "$(in_ct php -r 'echo ini_get("memory_limit");')"

  expect "apache Server header" Apache \
    "$(in_ct curl -sI http://localhost/__verify.php | tr -d '\r' | awk -F': ' 'tolower($1) == "server" { print $2 }')"
  expect "apache TRACE" 405 "$(in_ct curl -s -o /dev/null -w '%{http_code}' -X TRACE http://localhost/)"
  expect "apache directory listing" 403 "$(in_ct curl -s -o /dev/null -w '%{http_code}' http://localhost/__verify_dir/)"
fi

RUNNING=$(in_ct bash -c 'cat /proc/[0-9]*/comm' | sort -u)
MISSING=""
# supervisord starts fpm through the /usr/sbin/php-fpm symlink, hence no version in its name
for P in supervisord apache2 php-fpm cron rsyslogd; do
  grep -qxF "$P" <<< "$RUNNING" || MISSING="$MISSING $P"
done
expect "supervised processes (missing)" "" "${MISSING# }"

if [ "$FAILED" -gt 0 ]; then
  echo "verify $IMAGE: $FAILED check(s) FAILED"
  exit 1
fi
echo "verify $IMAGE: all checks passed"
