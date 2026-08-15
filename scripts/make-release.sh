#!/usr/bin/env bash
# LookaRetro — build release bundles (per-OS zips + theme zip) into dist/.
#
# Usage:
#     scripts/make-release.sh [version]
#
# The zips contain the installer + configs + theme + docs for each platform
# (NOT the emulator binaries — those are downloaded from official sources at
# install time). GitHub also auto-attaches the source archive on a tag.
set -euo pipefail

VERSION="${1:-1.0.0}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$REPO_DIR/dist"
STAGE="$DIST/stage"

rm -rf "$STAGE"
mkdir -p "$STAGE"

# --- common files shared by every platform bundle -------------------------
copy_common() {
    local dest="$1"
    mkdir -p "$dest/config/platform" "$dest/config/cores" "$dest/config/dolphin" \
             "$dest/theme/LookaRetro" "$dest/docs" "$dest/catalog"
    cp "$REPO_DIR/README.md" "$REPO_DIR/LICENSE" "$dest/"
    cp "$REPO_DIR/config/retroarch.cfg" "$dest/config/"
    cp "$REPO_DIR/config/cores/"*.cfg "$dest/config/cores/"
    cp "$REPO_DIR/config/dolphin/GFX.ini" "$dest/config/dolphin/"
    cp -R "$REPO_DIR/theme/LookaRetro/." "$dest/theme/LookaRetro/"
    cp "$REPO_DIR/docs/"*.md "$dest/docs/"
    cp "$REPO_DIR/catalog/open-source.tsv" "$dest/catalog/"
}

# --- macOS ----------------------------------------------------------------
M="$STAGE/macos/LookaRetro"
copy_common "$M"
mkdir -p "$M/lib" "$M/launchd"
cp "$REPO_DIR/install-macos.sh" "$REPO_DIR/uninstall-macos.sh" "$M/"
cp "$REPO_DIR/lib/launch.sh" "$REPO_DIR/lib/import-roms.sh" "$REPO_DIR/lib/fetch-and-play.sh" "$REPO_DIR/lib/make-open-source-catalog.sh" "$M/lib/"
cp "$REPO_DIR/config/platform/macos.cfg" "$M/config/platform/"
cp "$REPO_DIR/launchd/"*.plist "$M/launchd/"

# --- Linux ----------------------------------------------------------------
L="$STAGE/linux/LookaRetro"
copy_common "$L"
mkdir -p "$L/lib" "$L/systemd"
cp "$REPO_DIR/install-linux.sh" "$REPO_DIR/uninstall-linux.sh" "$L/"
cp "$REPO_DIR/lib/launch.sh" "$REPO_DIR/lib/import-roms.sh" "$REPO_DIR/lib/fetch-and-play.sh" "$REPO_DIR/lib/make-open-source-catalog.sh" "$L/lib/"
cp "$REPO_DIR/config/platform/linux.cfg" "$L/config/platform/"
cp "$REPO_DIR/systemd/"*.service "$REPO_DIR/systemd/"*.desktop "$REPO_DIR/systemd/"*.conf "$L/systemd/"

# --- Windows --------------------------------------------------------------
W="$STAGE/windows/LookaRetro"
copy_common "$W"
mkdir -p "$W/lib"
cp "$REPO_DIR/install-windows.ps1" "$REPO_DIR/uninstall-windows.ps1" "$W/"
cp "$REPO_DIR/lib/import-roms.ps1" "$REPO_DIR/lib/fetch-and-play.ps1" "$REPO_DIR/lib/make-open-source-catalog.ps1" "$W/lib/"
cp "$REPO_DIR/config/platform/windows.cfg" "$W/config/platform/"

# --- theme only -----------------------------------------------------------
T="$STAGE/theme/LookaRetro"
mkdir -p "$T"
cp -R "$REPO_DIR/theme/LookaRetro/." "$T/"

# --- zip ------------------------------------------------------------------
mkdir -p "$DIST"
( cd "$STAGE/macos"   && zip -q -r "$DIST/LookaRetro-v${VERSION}-macos.zip"   LookaRetro )
( cd "$STAGE/linux"   && zip -q -r "$DIST/LookaRetro-v${VERSION}-linux.zip"   LookaRetro )
( cd "$STAGE/windows" && zip -q -r "$DIST/LookaRetro-v${VERSION}-windows.zip" LookaRetro )
( cd "$STAGE/theme"   && zip -q -r "$DIST/LookaRetro-theme-v${VERSION}.zip"   LookaRetro )

rm -rf "$STAGE"

echo "Release bundles written to $DIST:"
ls -1 "$DIST"
echo
echo "To publish (GitHub CLI):"
echo "  gh release create v$VERSION $DIST/*.zip --title \"LookaRetro v$VERSION\" --generate-notes"
