#!/usr/bin/env bash
# LookaRetro — fetch-and-play: download an open-source ROM on first play, then launch.
#
# Usage:
#   fetch-and-play.sh <system> <target-file> <url>
#
# If <target-file> is still a 0-byte stub (created by make-open-source-catalog),
# it downloads <url> (direct ROM or .zip) to it. Then it launches the game via
# launch.sh. On later runs the ROM is already cached and it launches directly.
#
# Deployed to $RETRO_HOME/scripts/fetch-and-play.sh by the installers.
set -euo pipefail

SYSTEM="${1:-}"
TARGET="${2:-}"
URL="${3:-}"

if [[ -z "$SYSTEM" || -z "$TARGET" || -z "$URL" ]]; then
    echo "Usage: fetch-and-play.sh <system> <target-file> <url>" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$SCRIPT_DIR/launch.sh"

# Extension list used to locate the ROM inside a downloaded .zip.
rom_extensions() {
    case "$SYSTEM" in
        gbc)  echo "gb gbc" ;;
        gba)  echo "gba agb" ;;
        snes) echo "sfc smc fig swc" ;;
        n64)  echo "z64 n64 v64 ndd" ;;
        nds)  echo "nds" ;;
        psx)  echo "cue chd pbp iso" ;;
        wii)  echo "wbfs rvz iso" ;;
        *)    echo "" ;;
    esac
}

# --- download if needed ---------------------------------------------------
if [[ ! -s "$TARGET" ]]; then
    echo "LookaRetro: downloading $(basename "$TARGET") ..."
    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT
    DL="$TMP_DIR/download"

    if ! curl -fL --retry 3 -o "$DL" "$URL"; then
        echo "LookaRetro: download failed: $URL" >&2
        exit 1
    fi

    if [[ "$URL" == *.zip ]]; then
        unzip -q -o "$DL" -d "$TMP_DIR/extracted"
        found=""
        for e in $(rom_extensions); do
            found="$(find "$TMP_DIR/extracted" -type f -name "*.$e" -print -quit 2>/dev/null || true)"
            [[ -n "$found" ]] && break
        done
        if [[ -z "$found" ]]; then
            echo "LookaRetro: no ROM found inside $URL" >&2
            exit 1
        fi
        cp -f "$found" "$TARGET"
    else
        cp -f "$DL" "$TARGET"
    fi
    echo "LookaRetro: saved to $TARGET"
fi

# --- launch ---------------------------------------------------------------
exec "$LAUNCHER" "$SYSTEM" "$TARGET"
