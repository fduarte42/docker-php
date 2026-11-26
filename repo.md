# Docker PHP Repository

## Overview

Multi-arch (`linux/amd64`, `linux/arm64`) PHP-FPM + Apache images, one set per PHP version, for projects
to run on. Every image comes with the common PHP extensions and tools for web development. They are
rebuilt on a schedule and published to two registries:

- GHCR: `ghcr.io/fduarte42/docker-php`
- Docker Hub: `docker.io/fduarte42/docker-php`

**Repository**: [fduarte42/docker-php](https://github.com/fduarte42/docker-php)

Maintainer-level detail (build internals, conventions, pitfalls) is in `CLAUDE.md`. Terms are defined in
`CONTEXT.md`.

## Versions and tags

Each PHP version comes in one or two **variants**:

- **full** (`X.Y`): everything, including Chromium (for Puppeteer), wkhtmltopdf, pngquant and the
  MS core fonts.
- **slim** (`X.Y-slim`): full without the browser, PDF rendering and font packages.

**Flavors** are layered on top of a variant and can stack:

- `-debug`: xdebug, with `display_errors` on.
- `-oci`: Oracle Instant Client + oci8.
- `-sourceguardian`: the SourceGuardian loader.
- `-chartdirector`: ChartDirector.

| PHP | Variants | Flavors | Rebuilt |
|---|---|---|---|
| 5.6 | full | debug, oci | monthly |
| 7.4 | full | debug, oci, chartdirector | monthly |
| 8.2 | full, slim | debug, oci, sourceguardian, chartdirector (full only) | monthly |
| 8.3 | full, slim | debug, oci, sourceguardian | weekly |
| 8.4 | full, slim | debug, oci, sourceguardian | weekly |
| 8.5 | full, slim | debug, oci, sourceguardian | weekly |
| 8.6 | full, slim | debug, oci | weekly |

Tags include, for example, `8.4`, `8.4-debug`, `8.4-oci-debug`, `8.4-slim-oci-sourceguardian` and
`8.2-chartdirector-debug`. `./build-all.sh -L <version>` prints the exact list for a version.
The per-version gates live in `VERSION_TABLE` in `versions.sh`.

## What is in the image

- PHP-FPM + CLI from the sury.org packages, served by Apache. Debian trixie-slim base.
- supervisord as the process manager (not systemd). It runs apache2, php-fpm, cron, rsyslog and the
  one-shot `docker-php-init`.
- Extensions: apcu, bcmath, bz2, curl, gd, igbinary, imagick, imap, intl, ldap, mbstring, memcached,
  msgpack, mysqli, opcache, pdo_mysql, pdo_pgsql, pdo_sqlite, pgsql, raphf, redis, soap, sqlite3, ssh2,
  xml, xsl and zip. Version-specific additions:
  - decimal and http, from 7.4 on;
  - apc and propro on 5.6 and 7.4;
  - valkey_glide on 8.2–8.5.
- Composer, plus the global tools `phpcs`, `psalm` and `composer-require-checker` (the last two are
  missing on 5.6; `composer-require-checker` is also missing on 8.6, which no release supports yet).
- Node.js 24 and Yarn.
- `pdftk`: a PHP shim on top of `qpdf` that implements pdftk's command line. There is no Java in the
  images.
- OS and PHP time zone: `Europe/Berlin`. Locales: en_US, en_GB, fr_FR, es_ES, pt_PT, de_DE.

## Running it

```bash
docker run -d -p 80:80 -v /path/to/app:/var/www/html ghcr.io/fduarte42/docker-php:8.4
```

- `WORKDIR /var/www/html`, `EXPOSE 80`.
- `DOCUMENT_ROOT` (default `/`) is appended to `/var/www/html` for the Apache vhost.
- **Own ini settings:** mount a file at `/usr/local/etc/php/conf.d/zzz-custom.ini`. cli and fpm both
  load it last.
- **Host ownership:** `-e WWW_DATA_UID=$(id -u) -e WWW_DATA_GID=$(id -g)` remaps `www-data` to your
  ids before anything starts, so files written in bind mounts are owned by you.
- **SSH:** `-e SSH_AUTH_PORT=<port>` forwards an SSH agent to `/tmp/ssh-agent.sock`. Alternatively,
  mount a `/ssh` directory with `id_*` keys.
- **GPG:** mount `/gnupg` containing `gpg-key.asc`, `gpg-secret-key.asc` and `trust.txt`.
- **Cron:** put a crontab at `/tmp/crontab`. It is installed for `www-data`, and the jobs see the
  container environment.
- **Reloads:** `www-data` may run exactly two commands with passwordless sudo,
  `/etc/init.d/apache2 reload` and `/usr/local/bin/php-fpm-reload.sh`.
- **Hardening:** `display_errors` off and `log_errors` on (except in `-debug`), `ServerTokens Prod`,
  no TRACE, no directory listings, and no ghostscript.

## Building

```bash
./build-all.sh -h                              # usage
./build-all.sh -l -V -p linux/amd64 -s 8.4     # local single-arch build of the 8.4 slim chain, verified
./verify-image.sh fduarte42/docker-php:8.4 8.4 # check one image against the runtime contract
```

Without `-l`, `build-all.sh` **pushes** to the registries. Because local builds use `--load`, pair `-l`
with a single `-p` platform.

`verify-image.sh` checks the following:

- config, environment and modules;
- ini values, time zone and locales;
- sudoers and the Composer tools;
- pdftk and the uid remap;
- a live request through Apache to php-fpm.

## CI

`.github/workflows/docker-build.yml`:

- **Weekly** (Thursday 00:00 UTC): 8.3, 8.4, 8.5, 8.6.
- **Monthly** (1st, 12:00 UTC): 5.6, 7.4, 8.2.
- **Manual** (`workflow_dispatch`): `all`, `weekly`, `monthly`, or a list of versions.

Each version/variant builds natively per architecture (arm64 on an arm64 runner), is verified with `-V`,
and is pushed as `TAG-amd64` / `TAG-arm64`. A final `merge` job joins those into the multi-arch `TAG`.
An image that fails verification never reaches its public tag.
