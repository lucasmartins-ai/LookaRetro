#!/usr/bin/env bash
# LookaRetro — game launcher dispatcher (macOS + Linux).
#
# Usage:
#   launch.sh <system> <rom-path>
#
# <system> is one of: snes gbc gba n64 nds psx wii
#
# Called by Pegasus Frontend from each system's metadata.pegasus.txt via the
# `launch:` line. Deployed to $RETRO_HOME/scripts/launch.sh by the installer.
set -euo pipefail

SYSTEM="${1:-}"
ROM="${2:-}"

if [[ -z "$SYSTEM" || -z "$ROM" ]]; then
    echo "Usage: launch.sh <system> <rom-path>" >&2
    exit 2
fi

OS="$(uname -s)"

# ---------------------------------------------------------------------------
# Emulator invocations per OS
# ---------------------------------------------------------------------------
if [[ "$OS" == "Darwin" ]]; then
    RETROARCH="/Applications/RetroArch.app/Contents/MacOS/RetroArch"
    DUCKSTATION="/Applications/DuckStation.app/Contents/MacOS/DuckStation"
    DOLPHIN="/Applications/Dolphin.app/Contents/MacOS/Dolphin"
    CORES_DIR="${CORES_DIR:-$HOME/Library/Application Support/RetroArch/cores}"
    CORE_EXT="dylib"
elif [[ "$OS" == "Linux" ]]; then
    # Emulators are installed as Flatpaks (see install-linux.sh).
    RETROARCH=( flatpak run org.libretro.RetroArch )
    DUCKSTATION=( flatpak run org.duckstation.DuckStation )
    DOLPHIN=( flatpak run org.DolphinEmu.dolphin-emu )
    CORES_DIR="${CORES_DIR:-$HOME/.var/app/org.libretro.RetroArch/config/retroarch/cores}"
    CORE_EXT="so"
else
    echo "Unsupported OS: $OS" >&2
    exit 2
fi

case "$SYSTEM" in
    snes) core="snes9x_libretro" ;;
    gbc)  core="gambatte_libretro" ;;
    gba)  core="mgba_libretro" ;;
    n64)  core="mupen64plus_next_libretro" ;;
    nds)  core="melonds_libretro" ;;
    psx)
        exec "${DUCKSTATION[@]}" -fastboot -fullscreen -- "$ROM"
        ;;
    wii)
        exec "${DOLPHIN[@]}" -e "$ROM"
        ;;
    *)
        echo "Unknown system: $SYSTEM" >&2
        echo "Valid systems: snes gbc gba n64 nds psx wii" >&2
        exit 2
        ;;
esac

exec "${RETROARCH[@]}" -L "$CORES_DIR/${core}.${CORE_EXT}" "$ROM"
