# docker-php — custom PHP container images

Builds and publishes multi-arch PHP-FPM + Apache container images for several PHP versions and feature
flavors. **There is no application code and no `composer.json` here** — the deliverable is the images.
Published to `ghcr.io/fduarte42/docker-php` and `docker.io/fduarte42/docker-php`.

## What this repo is
- Base image: `debian:trixie-slim`. PHP comes from the sury.org APT repo, directly from `packages.sury.org`.
  The `mirrors.dotsrc.org/deb.sury.org` mirror was used while the direct source was down (`f719207`) and
  dropped again because it lags sury releases: on the 8.5.13 release day its index listed packages whose
  `.deb`s still 404'd, failing every amd64 job that apt-installed anything from sury (run `44567900251`).
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
./build-all.sh -L -n 8.4               # print the tags it WOULD build, touch nothing
./build-all.sh -M 7.4 8.2              # print the CI job matrix (JSON), touch nothing
./build-all.sh -l -V -p linux/amd64 -s 8.4    # build locally and verify every tag right after it is built
./verify-image.sh fduarte42/docker-php:8.4-slim 8.4-slim   # check one image against the runtime contract
./build-all.sh -p linux/arm64 -t -arm64 8.4   # single arch into ...:8.4-arm64 etc (what CI does)
```
- No argument ⇒ the versions marked `default` in `VERSION_TABLE` (`8.2 8.3 8.4 8.5`; **not** 5.6/7.4, which
  CI does build). A version not in the table is rejected.
- Without `-l` the script builds with `--push` — it publishes. Always use `-l` when experimenting.
- Local-build friction to expect: `-l` maps to `--load`, which cannot export a multi-platform manifest
  into the docker image store, so pair `-l` with a single `-p` platform. `-l` also passes `--pull`, so
  derived flavors try to re-pull their base tag from the registry instead of using the just-loaded local
  image; build the base tag alone first, or accept that flavor chains only compose properly on a push build.
- Every buildx invocation goes through the `build <tag> <dockerfile> [extra args]` helper. Add a flavor
  by adding a `build` line, not by copying a 200-char command.
- `-L` and `-M` print to **stdout** and nothing else — the "Running locally/inside GitHub Actions" banner
  goes to stderr specifically so they stay pipeable. Keep it that way; CI parses both.
- `-t SUFFIX` appends to every tag *and* is passed as `--build-arg TAG_SUFFIX`, which the derived
  Dockerfiles splice into their `FROM`. That is what lets one arch build in isolation.
- Verification = `verify-image.sh <image-ref> <tag>`: the runtime contract below as checks (config, env,
  `php -m` in cli and fpm, ini values, tz/locales, sudoers, composer tools, pdftk, the uid remap, and a live
  boot of `CMD` with a request through apache → php-fpm and a mounted `zzz-custom.ini`). Expectations come
  from the tag name (variant, flavors), a required-module list with the `build.sh` version deltas, and the
  table (valkey_glide). Extra modules are fine; a missing one fails. It runs the image, so it refuses an
  image of another architecture. `-V` calls it per tag inside `build()`; CI uses `-V`, so a failing image
  fails its build job and `merge` never moves the public tag (the per-arch tag is already pushed by then).
  With `-l`, only the base tags verify meaningfully: their flavors re-pull the base from the registry.
  When you change the contract, change `verify-image.sh` with it. Nothing else to lint or test.

## Image chain (order matters — each flavor derives FROM the previously built tag)
`Dockerfile` is the only one built from Debian; it produces both **variants** (see `CONTEXT.md`):
`--target full` → `X.Y`, `--target slim` → `X.Y-slim`. Tag names never contain "full".
Everything else is `FROM ${BASE_IMAGENAME}:${PHP_VERSION}${FLAVOR}${TAG_SUFFIX}`, so `build-all.sh` must
keep building base → debug → oci → sourceguardian in that sequence:

| Dockerfile | derives from | produces |
|---|---|---|
| `Dockerfile` (`--target full`/`slim`) | `debian:trixie-slim` | `X.Y`, `X.Y-slim` |
| `Dockerfile-debug` | `X.Y` / `X.Y-slim` | `X.Y-debug`, `X.Y-slim-debug` |
| `Dockerfile-oci` | `X.Y`, `X.Y-debug`, `X.Y-slim`, `X.Y-slim-debug` | `X.Y-oci`, `X.Y-oci-debug`, `X.Y-slim-oci`, `X.Y-slim-oci-debug` |
| `Dockerfile-sourceguardian` | `X.Y`, `X.Y-oci`, `X.Y-slim`, `X.Y-slim-oci` | `…-sourceguardian` variants (8.2+ only) |
| `Dockerfile-chartdirector` | `X.Y`, `X.Y-debug` | `X.Y-chartdirector`, `X.Y-chartdirector-debug` (7.4 and 8.2 only, non-slim; the vendored tarballs ship `phpchartdir<ver>.dll` up to 8.3 — nothing for 8.4/8.5) |

Which images a version gets is decided in one place: `VERSION_TABLE` in `versions.sh` (columns
`default`, `slim`, `sourceguardian`, `chartdirector`, `valkey-glide`), queried with `has <version> <feature>`.
The build loop, the valkey-glide builder stage (`--build-arg VALKEY_GLIDE=yes|no`) and the CI matrix (`-M`)
and `verify-image.sh` all read it (both `source` the file). **Adding a new PHP version means** a table row, its package branches in `build.sh` (those stay
next to their `apt-get` on purpose, not in the table), and adding it to `WEEKLY` or `MONTHLY` in the workflow's
`prepare` step.

## Layout
- `build-all.sh` — orchestration: option parsing, registry/tag selection (GHCR+Docker Hub under
  `GITHUB_ACTIONS=true`, else plain `fduarte42/docker-php`), and the full flavor matrix, expressed as
  `build <tag> <dockerfile> [extra args]` calls. Also owns the `valkey-glide-builder` registry cache
  (CI only) and, via `-L`, is the single source of truth for the tag list the CI merge job consumes.
- `build/Dockerfile*` — thin; they bind-mount their vendored assets and delegate the real work to a shell
  script. `Dockerfile`
  has four stages: `valkey-glide-builder` compiles the extension; `image` runs `build.sh` with `ARG VARIANT`
  (no default) and bind-mounts both the resulting `.so` and `packages/` (wkhtmltox debs) into that layer;
  `full` (= `image` + the Puppeteer `ENV`) and `slim` (= `image`) are the final targets. `build-all.sh`
  passes `--target` and `VARIANT` together via `variant_args` so they cannot disagree.
  `TARGETARCH`/`PHP_VERSION` are declared once above the first `FROM` and re-declared (bare) in the stages.
- `build/build.sh` — the actual image construction (APT repos, PHP + extensions, Apache, PHP ini, Composer,
  permissions) for both variants. It rejects any `VARIANT` other than `full`/`slim`. The whole slim delta
  sits in two places at the top: the `FULL_PACKAGES` array (`chromium`, `pngquant`,
  `ttf-mscorefonts-installer`, `xfonts-base`, `xfonts-75dpi`, spliced into the one big `apt-get install`)
  and the `if [ "$VARIANT" = full ]` block right after it (wkhtmltox `.deb` from the read-only
  `/tmp/packages` mount; it installs straight into `/usr/local/bin`). The msfonts EULA preseed runs for
  both; it is a no-op for slim.
- `build/build-valkey-glide.sh` — runs only in the `valkey-glide-builder` stage; produces
  `/out/valkey_glide.so`, or an empty `/out` when `VALKEY_GLIDE=no` (required arg, no default, like `VARIANT`;
  `build-all.sh` passes it from the table).
- `build/add-*.sh` — one per optional flavor: `add-debug.sh` (xdebug), `add-oci.sh` (Oracle Instant Client
  + pecl oci8), `add-sourceguardian.sh` (ixed loader), `add-chartdirector.sh`.
- `build/config/` — `supervisord.conf`, `keyboard`.
- `build/scripts/` — baked into the image: `docker-php-entrypoint`, `docker-php-init`, `cron-foreground`, `php-fpm-reload.sh`, `.bashrc`,
  `pdftk`.
- `build/packages/`, `build/extension/`, `build/driver/oracle/` — **vendored third-party binaries committed to
  git** (patched wkhtmltox debs, ChartDirector, SourceGuardian loaders, Oracle Instant Client zips). They are
  never `COPY`ed: a `COPY` + later `rm` still ships the files (all four Oracle zips, both arches, were
  ~139MB of every `-oci*` tag). Each Dockerfile bind-mounts its asset dir read-only for the one `RUN` that
  needs it — `packages/` at `/tmp/packages` for `build.sh`, `driver/oracle/` or `extension/` at
  `/tmp/vendor` for the flavor scripts. Scripts pick the file by exact name per `$TARGETARCH` (versions
  included in `add-oci.sh`) — replacing one means updating that script too, and must not try to delete it.
- `.github/workflows/docker-build.yml` — the only workflow. Two crons: weekly (Thu 00:00 UTC) builds the
  `WEEKLY` set **8.3, 8.4, 8.5**; monthly (1st, 12:00 UTC) builds the `MONTHLY` set **5.6, 7.4, 8.2**. Both
  lists live in the `prepare` step; the cron strings there must match the `on.schedule` entries exactly
  (an unmatched schedule fails `prepare` rather than building nothing). `run-name` shows weekly / monthly /
  `dispatch: <input>`. Three jobs:
  - `prepare` — picks the versions (cron → its set; `workflow_dispatch` input `php_versions`: `all` = both
    sets, `weekly`, `monthly`, or a space-separated list) and turns them into the job matrix via
    `./build-all.sh -M`, which lists only the `{php_version, variant}` pairs that build something (no slim
    jobs for 5.6/7.4) and fails on an unknown version. Dispatch one version to test it instead of the whole
    fan-out.
  - `build` — matrix of `job` (from `prepare`) × `amd64|arm64`, `fail-fast: false`, 2G swap, logs into
    both registries (`CR_PAT`, `DOCKERHUB_USER`, `DOCKERHUB_PAT`), then
    `./build-all.sh -V -s|-n -p linux/<arch> -t -<arch> <version>`. **arm64 runs on `ubuntu-24.04-arm`**
    (free for public repos), not under QEMU — `include:` maps `arch` → `runner`.
  - `merge` — `docker buildx imagetools create` per tag from `build-all.sh -L`, combining
    `TAG-amd64` + `TAG-arm64` into `TAG`, once per registry so no blobs are copied between them.
  This replaced a single job that built both platforms at once: arm64 was emulated on a 4-vCPU amd64
  runner, which made the Rust compile ~100 min and pushed `make install` past PIE's hardcoded 300s
  per-process timeout — `8.3-slim`/`8.5-slim` failed on it flakily (run `33710365591`). Native arm64
  removes both problems. Byproducts now public in both registries: per-arch `…-amd64`/`…-arm64` tags
  and `cache-valkey-glide-<version>-<arch>`. Nothing consumes them; they are safe to prune.
- `repo.md` — longer prose overview. Partly stale: the `unsupported/` legacy-version tree it describes was
  deleted (`80a703d`), and its `build-all.sh` usage predates the option flags. Prefer this file / the sources.

## Runtime contract of the images (don't break these for consumers)
Executable form: `verify-image.sh`. Keep the two in step.
- `WORKDIR /var/www/html`, `EXPOSE 80`, `CMD` = supervisord with `/etc/supervisor/conf.d/supervisord.conf`.
- Env: `DOCUMENT_ROOT=/` (spliced into the Apache vhost path), `PHP_GC_MAX_LIFETIME=1440`,
  `COMPOSER_HOME=/composer`, `COMPOSER_ALLOW_SUPERUSER=1`, `PATH` includes `/composer/vendor/bin`.
  Non-slim also sets `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true` and `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium`.
- Consumer ini override hook: `/usr/local/etc/php/conf.d/zzz-custom.ini` (symlinked into the version's
  `mods-available` and both cli/fpm `conf.d`) — for `docker-php` upstream compatibility. Keep it working.
- `docker-php-init` runtime inputs: `SSH_AUTH_PORT` (socat-forwarded agent at `/tmp/ssh-agent.sock`), or a
  mounted `/ssh` dir with `id_*` keys; GPG material from `/gnupg/{gpg-key.asc,gpg-secret-key.asc,trust.txt}`.
- `ENTRYPOINT` = `/usr/local/bin/docker-php-entrypoint` (`build/scripts/`), which `exec`s `CMD`. With
  `WWW_DATA_UID` / `WWW_DATA_GID` set (e.g. `-e WWW_DATA_UID=$(id -u) -e WWW_DATA_GID=$(id -g)`) it remaps
  www-data **before** supervisord starts — it can't live in `docker-php-init`, which supervisord runs in
  parallel with php-fpm/apache/cron. It re-owns image files with `find / -xdev` and moves existing numeric
  `user:33`/`group:33` ACL entries (access + default, perms kept) to the new ids — only where such an entry
  already exists: adding one elsewhere raises the ACL mask and loosens `.gnupg` (700) / `.ssh`. Anything
  not on the root fs (bind mounts, incl. their mount points) is skipped, so host files and host ACLs are
  never touched. For the same reason the uid is changed by editing `/etc/passwd`, **not** `usermod -u`
  (which chowns the home dir recursively, into a `/var/www/html` bind mount). Ids are switched last so the
  remap is idempotent and a failed run retries on restart. Needs root; no-op under `--user` or a consumer
  `ENTRYPOINT` override.
- `cron-foreground` installs `/tmp/crontab` for `www-data` and dumps the env to `/etc/environment` so cron
  jobs see it.
- `www-data` (uid 33) has passwordless sudo for exactly two commands: `/etc/init.d/apache2 reload` and
  `/usr/local/bin/php-fpm-reload.sh`. Its home `/var/www` is owned by `www-data` itself (non-recursive
  `chown` in `build.sh`), so tools can create `~/.cache`, `~/.local` etc. Don't use ACLs for this: the buildx
  layer export drops ACL xattrs, so published images carry **none**. The docker-plugin project relies on the
  `WWW_DATA_UID`/`WWW_DATA_GID` remap instead of ACLs.
- Globally installed via Composer in-image: `squizlabs/php_codesniffer`, `maglnet/composer-require-checker`
  (pinned to `3.8.0` on 7.4), `vimeo/psalm`. These are tools *for consuming projects*, not for this repo.

## Conventions to follow when editing
- PHP config goes in `/etc/php/${PHP_VERSION}/mods-available/<name>.ini` followed by `phpenmod <name>` —
  never edit `php.ini` in place.
- Version-specific package differences use the `[[ $PHP_VERSION =~ (…) ]]` branch idiom already in `build.sh`.
  PHP 8.5 gets memcached/raphf/http from sury like 8.2–8.4, but has its own branch because opcache is built
  into 8.5 (there is no `php8.5-opcache` package). Before sury packaged them they were compiled with `pecl`;
  a brand-new PHP version will likely need that again until sury catches up. If so, install the build deps
  (`php<ver>-dev`, `build-essential`, …) and purge them in the same step, and never call `pecl install <name>` /
  `pecl download` directly: pecl.php.net 404s the PEAR release metadata (`allreleases2.xml`) and
  intermittently 500s on downloads (run `39619156205`). Resolve the version from `rest/r/<pkg>/stable.txt`,
  fetch the tarball with `curl --retry 5 --retry-all-errors`, and `pecl install` the local file — see the oci8
  download in `add-oci.sh` (and the `pecl_install` helper removed from `build.sh` in git history).
- `valkey_glide` has no sury package either: a pinned, sha256-verified `pie.phar` builds it from the
  upstream source release. Because it compiles glide's Rust FFI core, that happens in its own
  `valkey-glide-builder` stage (`build/build-valkey-glide.sh`), gated by the table's `valkey-glide` column
  (8.2–8.5; glide needs PHP ≥ 8.2), which sets up the sury
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
  - The builder stage must install PHP from the **same** sury source as `build.sh`, otherwise the `.so`
    can miss the final image's Zend ABI. The `php -m | grep -qx valkey_glide` gate in `build.sh` is what
    catches that — keep it.
  - The install side in `build.sh` resolves the target directory with
    `php -r 'echo ini_get("extension_dir");'` (same idiom as `add-chartdirector.sh`), **not**
    `php-config${PHP_VERSION}` — `php${PHP_VERSION}-dev` is never installed in the final image.
  - `libprotobuf-c1` and `libffi8` must stay explicitly installed: the `.so` links against them and
    `apt-get autoremove` would otherwise take them.
  - With `VALKEY_GLIDE=no` the builder stage exits early leaving `/out` empty, and the
    `if [ -f /tmp/valkey-glide/valkey_glide.so ]` guard in `build.sh` skips the install. That is how 7.4
    still builds — don't replace the guard with a version regex.
  Bump `PIE_VERSION`/`PIE_SHA256`, `CBINDGEN_VERSION` + its two hashes, and `VALKEY_GLIDE_VERSION`
  together. PIE installs only the extension; the package's helper PHP classes are deliberately not in the
  image (consumers `composer require valkey-io/valkey-glide-php`).
- New flavor = `add-<name>.sh` + `Dockerfile-<name>` (ARG `PHP_VERSION`/`BASE_IMAGENAME`/`FLAVOR`/
  `TAG_SUFFIX`, `FROM ${BASE_IMAGENAME}:${PHP_VERSION}${FLAVOR}${TAG_SUFFIX}`) + `build` lines in
  `build-all.sh` for both slim and non-slim, placed after their base tag. Vendored files go under `build/`
  and are bind-mounted at `/tmp/vendor` on the script's `RUN` (copy `Dockerfile-chartdirector`), not `COPY`ed.
  **`TAG_SUFFIX` is not optional** — omit it and the flavor will pull the multi-arch base tag from the previous run instead of
  the per-arch tag this run just pushed.
- Every layer script ends with `apt-get clean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*`.
  Preserve that; image size is a goal.
- Deliberate security choices — do not "fix" them back: ghostscript is purged (ImageMagick attack surface,
  `3e790ef`), `display_errors=off` + `log_errors=on`, `ServerTokens Prod` / `ServerSignature Off` /
  `TraceEnable Off`, directory listing off, `javascript-common` conf disabled. (`build.sh` also purges python3, but that is
  dead: the NodeSource `nodejs` package depends on `python3`, so the main `apt-get install` brings it
  back; `verify-image.sh` does not check it.)
- PHP 5.6 builds only the non-slim chain (`5.6`, `-debug`, `-oci`, `-oci-debug`), like 7.4. Its deltas, all
  `(5\.6)` branches: no `decimal`/`http` packages, Composer pinned to the 2.2 LTS channel, no psalm /
  composer-require-checker, xdebug 2 `remote_*` settings in `add-debug.sh`, oci8 `2.0.12`.
- `pdftk` is **not** pdftk-java (that pulled ~195MB of JRE): `/usr/local/bin/pdftk` is a PHP shim
  (`build/scripts/pdftk`) that implements pdftk's CLI grammar on top of the `qpdf` package — cat, shuffle,
  burst, rotate, stamp/background (+multi), fill_form (FDF/XFDF, via `qpdf --update-from-json` +
  `--generate-appearances`), dump_data[_fields][_utf8], update_info[_utf8], input_pw/owner_pw/user_pw/allow,
  flatten. Unsupported operations exit 1 with a message. It runs on every image, so it **must stay PHP 5.6
  compatible** (`docker run --rm -v $PWD/build/scripts:/s php:5.6-cli php -l /s/pdftk`). `encrypt_128bit` maps
  to AES-128, not RC4: qpdf 12 refuses RC4 as weak crypto.
- Timezone/locale are fixed: `Europe/Berlin` for the OS (`/etc/localtime` — what `date`, cron and syslog use)
  and PHP (`date.timezone`), locales `en_US en_GB fr_FR es_ES pt_PT de_DE`. On trixie `dpkg-reconfigure
  tzdata` derives `/etc/timezone` from the `/etc/localtime` symlink, so `build.sh` sets the symlink; images
  built before that fix run the OS in UTC.

## Branching
Default branch: `master`; history is committed straight to it (only remote-tracking merges, no feature-branch
convention in use). Dependabot branches exist for the deleted `unsupported/*` puppeteer scripts and can be
ignored. Since any non-`-l` build pushes public tags, confirm before running a publishing build.

## Do / Don't
- DO put a full-only addition in `FULL_PACKAGES` / the `VARIANT = full` block of `build.sh`, nowhere else.
- DO build locally (`-l -p linux/amd64`) and start the container to verify before pushing.
- DON'T add a package without deciding whether it belongs in slim.
- DON'T reorder builds in `build-all.sh` so a flavor precedes the tag it derives `FROM`.
- DON'T commit new large vendored binaries without replacing the old ones and updating the matching glob/version.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on fduarte42/docker-php, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root (created lazily). See `docs/agents/domain.md`.
