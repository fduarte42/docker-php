# docker-php — custom PHP container images

Builds and publishes multi-arch PHP-FPM + Apache container images for several PHP versions and feature
flavors. **There is no application code and no `composer.json` here** — the deliverable is the images.
Published to `ghcr.io/fduarte42/docker-php` and `docker.io/fduarte42/docker-php`.

## What this repo is
- Base image: `debian:trixie-slim`. PHP comes from the sury.org APT repo (currently via the
  `mirrors.dotsrc.org/deb.sury.org` mirror — the direct source was down, see commit `f719207`).
- Process manager is **supervisord**, not systemd; it runs apache2, php-fpm, cron, rsyslog and the
  one-shot `docker-php-init`.
- Platforms: `linux/amd64,linux/arm64` by default. Arch-specific handling is done via `$TARGETARCH`
  inside the `add-*.sh` scripts.

## Commands (these are the only ones — no Makefile, no composer scripts, no test suite)
```bash
./build-all.sh -h                      # real usage/help, read it before changing the script
./build-all.sh 8.4                     # all non-slim + slim flavors of 8.4, PUSHES to both registries
./build-all.sh -l -p linux/amd64 8.4   # local only (--load --pull --no-cache), single arch
./build-all.sh -s 8.4                  # slim flavors only
./build-all.sh -n 8.4                  # skip slim flavors
```
- No argument ⇒ versions default to `8.2 8.3 8.4 8.5` (note: **not** 7.4, which CI does build).
- Without `-l` the script builds with `--push` — it publishes. Always use `-l` when experimenting.
- Local-build friction to expect: `-l` maps to `--load`, which cannot export a multi-platform manifest
  into the docker image store, so pair `-l` with a single `-p` platform. `-l` also passes `--pull`, so
  derived flavors try to re-pull their base tag from the registry instead of using the just-loaded local
  image; build the base tag alone first, or accept that flavor chains only compose properly on a push build.
- There is nothing to lint or test. Verification = build the image and run it.

## Image chain (order matters — each flavor derives FROM the previously built tag)
`Dockerfile` → `X.Y` and `Dockerfile-slim` → `X.Y-slim` are the only two images built from Debian.
Everything else is `FROM ${BASE_IMAGENAME}:${PHP_VERSION}${FLAVOR}`, so `build-all.sh` must keep building
base → debug → oci → sourceguardian in that sequence:

| Dockerfile | derives from | produces |
|---|---|---|
| `Dockerfile` / `Dockerfile-slim` | `debian:trixie-slim` | `X.Y`, `X.Y-slim` |
| `Dockerfile-debug` | `X.Y` / `X.Y-slim` | `X.Y-debug`, `X.Y-slim-debug` |
| `Dockerfile-oci` | `X.Y`, `X.Y-debug`, `X.Y-slim`, `X.Y-slim-debug` | `X.Y-oci`, `X.Y-oci-debug`, `X.Y-slim-oci`, `X.Y-slim-oci-debug` |
| `Dockerfile-sourceguardian` | `X.Y`, `X.Y-oci`, `X.Y-slim`, `X.Y-slim-oci` | `…-sourceguardian` variants (8.2+ only) |
| `Dockerfile-chartdirector` | `7.4`, `7.4-debug` | `7.4-chartdirector`, `7.4-chartdirector-debug` (7.4 only) |

Version gates in `build-all.sh` are literal regexes (`8\.2|8\.3|8\.4|8\.5`): **adding a new PHP version means
editing those regexes**, the `VERSIONS` default, the version branches in `build.sh`/`build-slim.sh`, the gate in
`build/build-valkey-glide.sh`, and the CI matrix. Known dead combination: `./build-all.sh -s 7.4` builds nothing (slim block is gated to 8.2+),
yet the CI matrix still schedules that job.

## Layout
- `build-all.sh` — orchestration: option parsing, registry/tag selection (GHCR+Docker Hub under
  `GITHUB_ACTIONS=true`, else plain `fduarte42/docker-php`), and the full flavor matrix.
- `build/Dockerfile*` — thin; they copy assets and delegate the real work to a shell script. `Dockerfile`
  and `Dockerfile-slim` are two-stage: a `valkey-glide-builder` stage compiles the extension, and the
  final stage bind-mounts the resulting `.so` into the `build.sh` layer. `TARGETARCH`/`PHP_VERSION` are
  declared once above the first `FROM` and re-declared (bare) in both stages.
- `build/build.sh`, `build/build-slim.sh` — the actual image construction (APT repos, PHP + extensions,
  Apache, PHP ini, Composer, permissions). **Near-duplicates that must be kept in sync.** The slim delta is
  exactly: no chromium, no wkhtmltox `.deb`, no `ttf-mscorefonts-installer`/`xfonts-base`/`xfonts-75dpi`,
  no `pngquant`.
- `build/build-valkey-glide.sh` — runs only in the `valkey-glide-builder` stage; produces
  `/out/valkey_glide.so` (empty `/out` for versions outside `8.2–8.5`). Shared verbatim by both Dockerfiles.
- `build/add-*.sh` — one per optional flavor: `add-debug.sh` (xdebug), `add-oci.sh` (Oracle Instant Client
  + pecl oci8), `add-sourceguardian.sh` (ixed loader), `add-chartdirector.sh`.
- `build/config/` — `supervisord.conf`, `keyboard`.
- `build/scripts/` — baked into the image: `docker-php-init`, `cron-foreground`, `php-fpm-reload.sh`, `.bashrc`.
- `build/packages/`, `build/extension/`, `build/driver/oracle/` — **vendored third-party binaries committed to
  git** (patched wkhtmltox debs, ChartDirector, SourceGuardian loaders, Oracle Instant Client zips). Filenames
  are matched by glob in the Dockerfiles and by exact version string in `add-oci.sh` — replacing one means
  updating that script too.
- `.github/workflows/docker-build.yml` — weekly (Thu 00:00 UTC) + `workflow_dispatch`. Matrix of
  PHP `7.4, 8.2, 8.3, 8.4, 8.5` × `slim | non-slim`, `fail-fast: false`, adds 2G swap, logs into both
  registries (`CR_PAT`, `DOCKERHUB_USER`, `DOCKERHUB_PAT`), then calls `./build-all.sh -s|-n <version>`.
  Since valkey_glide compiles a Rust core, the `valkey-glide-builder` stage is the long pole: measured
  locally on 16 cores it is ~8.5 min for `linux/amd64` but ~37.5 min for `linux/arm64` under QEMU (4.4x).
  It is a separate stage, so buildx runs it concurrently with the main `build.sh` layer — total time is
  roughly `max(compile, rest)` rather than their sum. On 4-vCPU runners building both platforms at once it
  is far slower again, so if a job ever hits the 6-hour limit, split the matrix per platform (single `-p`,
  then merge manifests) or use arm64 runners rather than trimming the extension.
- `repo.md` — longer prose overview. Partly stale: the `unsupported/` legacy-version tree it describes was
  deleted (`80a703d`), and its `build-all.sh` usage predates the option flags. Prefer this file / the sources.

## Runtime contract of the images (don't break these for consumers)
- `WORKDIR /var/www/html`, `EXPOSE 80`, `CMD` = supervisord with `/etc/supervisor/conf.d/supervisord.conf`.
- Env: `DOCUMENT_ROOT=/` (spliced into the Apache vhost path), `PHP_GC_MAX_LIFETIME=1440`,
  `COMPOSER_HOME=/composer`, `COMPOSER_ALLOW_SUPERUSER=1`, `PATH` includes `/composer/vendor/bin`.
  Non-slim also sets `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true` and `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium`.
- Consumer ini override hook: `/usr/local/etc/php/conf.d/zzz-custom.ini` (symlinked into the version's
  `mods-available` and both cli/fpm `conf.d`) — for `docker-php` upstream compatibility. Keep it working.
- `docker-php-init` runtime inputs: `SSH_AUTH_PORT` (socat-forwarded agent at `/tmp/ssh-agent.sock`), or a
  mounted `/ssh` dir with `id_*` keys; GPG material from `/gnupg/{gpg-key.asc,gpg-secret-key.asc,trust.txt}`.
- `cron-foreground` installs `/tmp/crontab` for `www-data` and dumps the env to `/etc/environment` so cron
  jobs see it.
- `www-data` (uid 33) has ACLs on `/var/www` (`setfacl -R [-d] -m u:33:rwX`) and passwordless sudo for exactly
  two commands: `/etc/init.d/apache2 reload` and `/usr/local/bin/php-fpm-reload.sh`.
- Globally installed via Composer in-image: `squizlabs/php_codesniffer`, `maglnet/composer-require-checker`
  (pinned to `3.8.0` on 7.4), `vimeo/psalm`. These are tools *for consuming projects*, not for this repo.

## Conventions to follow when editing
- PHP config goes in `/etc/php/${PHP_VERSION}/mods-available/<name>.ini` followed by `phpenmod <name>` —
  never edit `php.ini` in place.
- Version-specific package differences use the `[[ $PHP_VERSION =~ (…) ]]` branch idiom already in `build.sh`.
  PHP 8.5 has no sury builds for memcached/raphf/http — those are compiled with `pecl` and the build deps
  (`php8.5-dev`, `build-essential`, …) are purged again in the same step. Keep that purge.
- `valkey_glide` has no sury package either: a pinned, sha256-verified `pie.phar` builds it from the
  upstream source release. Because it compiles glide's Rust FFI core, that happens in its own
  `valkey-glide-builder` stage (`build/build-valkey-glide.sh`), gated to 8.2–8.5, which sets up the sury
  repo, installs `php${PHP_VERSION}-cli`/`-dev` + a rustup toolchain (`VALKEY_GLIDE_RUST_VERSION`) +
  `cmake`, `libffi-dev`, `libssl-dev`, `libprotobuf-c-dev`, `python3` (needed by `config.m4`) and **both**
  protobuf compilers — `protoc` for glide-core's build script and `protoc-c` for the extension's C
  protobuf files. **Nothing in that stage is purged**: it is thrown away wholesale, and only
  `/out/valkey_glide.so` reaches the image. Non-obvious constraints, all found the hard way:
  - The `.so` is handed over with `RUN --mount=type=bind,from=valkey-glide-builder` on the `build.sh`
    line, **not** a `COPY --from=`. A `COPY` leaves a ~50MB layer in the image for a file that only
    exists to be installed into the extension dir, and a later `rm` cannot reclaim it. The flip side:
    the mount is read-only, so `build.sh` must not try to delete `/tmp/valkey-glide`.
  - `cbindgen` comes from a pinned upstream release binary per `$TARGETARCH`, **not** the trixie package:
    0.27 does not understand edition-2024 `#[unsafe(no_mangle)]` and silently emits an empty
    `glide_bindings.h`, so the C compile fails with "incomplete type" errors instead of anything obvious.
  - The rustup pin must satisfy glide's locked AWS SDK crates (≥1.91.1 as of extension 1.1.2); 1.90 is
    rejected outright by cargo.
  - The builder stage must install PHP from the **same** sury mirror as `build.sh`, otherwise the `.so`
    can miss the final image's Zend ABI. The `php -m | grep -qx valkey_glide` gate in `build.sh` is what
    catches that — keep it.
  - The install side in `build.sh`/`build-slim.sh` resolves the target directory with
    `php -r 'echo ini_get("extension_dir");'` (same idiom as `add-chartdirector.sh`), **not**
    `php-config${PHP_VERSION}` — `php${PHP_VERSION}-dev` is never installed in the final image.
  - `libprotobuf-c1` and `libffi8` must stay explicitly installed: the `.so` links against them and
    `apt-get autoremove` would otherwise take them.
  - For a PHP version outside the gate the builder stage exits early leaving `/out` empty, and the
    `if [ -f /tmp/valkey-glide/valkey_glide.so ]` guard in `build.sh` skips the install. That is how 7.4
    still builds — don't replace the guard with a version regex.
  Bump `PIE_VERSION`/`PIE_SHA256`, `CBINDGEN_VERSION` + its two hashes, and `VALKEY_GLIDE_VERSION`
  together. PIE installs only the extension; the package's helper PHP classes are deliberately not in the
  image (consumers `composer require valkey-io/valkey-glide-php`).
- New flavor = `add-<name>.sh` + `Dockerfile-<name>` (ARG `PHP_VERSION`/`BASE_IMAGENAME`/`FLAVOR`, `FROM`
  the composed tag) + build lines in `build-all.sh` for both slim and non-slim, placed after their base tag.
- Every layer script ends with `apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*`.
  Preserve that; image size is a goal.
- Deliberate security choices — do not "fix" them back: ghostscript is purged (ImageMagick attack surface,
  `3e790ef`), `display_errors=off` + `log_errors=on`, `ServerTokens Prod` / `ServerSignature Off` /
  `TraceEnable Off`, directory listing off, python3 purged, `javascript-common` conf disabled.
- Timezone/locale are fixed: `Europe/Berlin`, locales `en_US en_GB fr_FR es_ES pt_PT de_DE`.

## Branching
Default branch: `master`; history is committed straight to it (only remote-tracking merges, no feature-branch
convention in use). Dependabot branches exist for the deleted `unsupported/*` puppeteer scripts and can be
ignored. Since any non-`-l` build pushes public tags, confirm before running a publishing build.

## Do / Don't
- DO change `build.sh` and `build-slim.sh` together unless the change is intentionally non-slim-only.
- DO build locally (`-l -p linux/amd64`) and start the container to verify before pushing.
- DON'T add a package without deciding whether it belongs in slim.
- DON'T reorder builds in `build-all.sh` so a flavor precedes the tag it derives `FROM`.
- DON'T commit new large vendored binaries without replacing the old ones and updating the matching glob/version.
