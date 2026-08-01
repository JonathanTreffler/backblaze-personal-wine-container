#!/bin/sh
# Build a patched wineserver from the WineHQ source package.
#
# The rest of Wine still comes from the WineHQ binary package, so the wineserver
# must be built from *exactly* the same source and package revision - the
# wineserver protocol is version-locked and a mismatch makes Wine refuse to
# start. That is why the source package version is pinned by the caller to the
# same string used for `apt-get install winehq-stable=...`, and why every step
# below fails loudly instead of falling back to something that merely looks
# close enough.
#
# Usage: build-wineserver.sh <ubuntu-suite> <wine-package-version> <patch-file> <output-binary>
#   e.g. build-wineserver.sh jammy 11.0.0.0~jammy-1 /patches/0001-....patch /out/wineserver

set -eu

SUITE="$1"
WINE_PACKAGE_VERSION="$2"
PATCH_FILE="$3"
OUTPUT="$4"

WORKDIR=/usr/src/wine-build

[ -f "$PATCH_FILE" ] || { echo "ERROR: patch not found: $PATCH_FILE" >&2; exit 1; }

# WineHQ's own apt repo, source component only. We never install binaries here.
install -dm755 /etc/apt/keyrings
curl -fsSL https://dl.winehq.org/wine-builds/winehq.key -o /etc/apt/keyrings/winehq-archive.key
cat > /etc/apt/sources.list.d/winehq-src.sources <<EOF
Types: deb-src
URIs: https://dl.winehq.org/wine-builds/ubuntu
Suites: ${SUITE}
Components: main
Signed-By: /etc/apt/keyrings/winehq-archive.key
EOF
apt-get update

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Exact revision or nothing: apt fails if this version is not in the index.
# APT::Sandbox::User=root avoids the unsandboxed-download permission warning
# turning into a failure when fetching into a root-owned directory.
apt-get source -o APT::Sandbox::User=root "wine=${WINE_PACKAGE_VERSION}"

SRCDIR="$(find . -maxdepth 1 -mindepth 1 -type d -name 'wine-*' -print -quit)"
[ -n "$SRCDIR" ] || { echo "ERROR: unpacked wine source tree not found" >&2; exit 1; }
cd "$SRCDIR"

# Apply only the intended patch. No fuzz, no reversal guessing, no backups: if
# the upstream code has moved, the build stops here rather than producing a
# wineserver that silently lacks the fix.
echo "Applying $PATCH_FILE"
patch -p1 --batch --fuzz=0 --forward --no-backup-if-mismatch < "$PATCH_FILE"

./configure --enable-win64 --without-x --without-freetype --without-mingw \
    --disable-tests --without-alsa --without-pulse --without-oss --without-cups \
    --without-fontconfig --without-gnutls --without-gstreamer --without-opengl \
    --without-sdl --without-udev --without-usb --without-v4l2 --without-wayland \
    --without-pcap --without-netapi --without-dbus --without-inotify >/dev/null

# Only the server target; nothing else from this tree ships in the image.
make -j"$(nproc)" server/wineserver
strip server/wineserver

install -Dm755 server/wineserver "$OUTPUT"
"$OUTPUT" --version
