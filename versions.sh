# Sourced by build-all.sh and verify-image.sh; not executable on its own.
# What each PHP version gets - the only place these per-version gates live. build-all.sh (build loop,
# valkey-glide builder stage via --build-arg VALKEY_GLIDE, CI matrix via -M) and verify-image.sh all ask has().
# default: built when no versions are given. slim: has the slim variant (and its flavors).
# Package differences between versions are not in here - they stay next to their apt-get in build.sh.
#         default  slim  sourceguardian  chartdirector  valkey-glide
VERSION_TABLE="
5.6       -        -     -               -              -
7.4       -        -     -               yes            -
8.2       yes      yes   yes             yes            yes
8.3       yes      yes   yes             -              yes
8.4       yes      yes   yes             -              yes
8.5       yes      yes   yes             -              yes
8.6       -        yes   -               -              -
"
FEATURES="default slim sourceguardian chartdirector valkey-glide"

# has <version> <feature> - succeeds if VERSION_TABLE marks <feature> for <version>
function has() {
  local COL=2 F
  for F in $FEATURES; do
    [ "$F" = "$2" ] && break
    COL=$((COL + 1))
  done
  if [ "$F" != "$2" ]; then
    echo "has: unknown feature '$2'" >&2
    exit 1
  fi
  awk -v v="$1" -v c="$COL" '$1 == v && $c == "yes" { ok = 1 } END { exit !ok }' <<< "$VERSION_TABLE"
}

function known_versions() {
  awk 'NF { print $1 }' <<< "$VERSION_TABLE"
}
