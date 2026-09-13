#!/usr/bin/env bash
# LookaRetro — game launcher dispatcher (macOS + Linux).
#
# Usage:
#   launch.sh <system> <rom-path>
#
# <system> is one of: snes gbc gba n64 nds psx wii 3ds switch psvita
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
    RETROARCH=( "/Applications/RetroArch.app/Contents/MacOS/RetroArch" )
    DUCKSTATION=( "/Applications/DuckStation.app/Contents/MacOS/DuckStation" )
    DOLPHIN=( "/Applications/Dolphin.app/Contents/MacOS/Dolphin" )
    AZAHAR=( "/Applications/Azahar.app/Contents/MacOS/azahar" )
    RYUJINX=( "/Applications/Ryujinx.app/Contents/MacOS/Ryujinx" )
    VITA3K=( "/Applications/Vita3K.app/Contents/MacOS/Vita3K" )
    CORES_DIR="${CORES_DIR:-$HOME/Library/Application Support/RetroArch/cores}"
    CORE_EXT="dylib"
    # Pegasus Frontend has no arm64 macOS build (it runs x86_64 under Rosetta),
    # so every child it spawns would execute as x86_64 too — and the arm64
    # libretro cores would fail to load ("incompatible architecture"). Force the
    # emulators to run natively on Apple Silicon.
    #
    # Detect the HARDWARE via sysctl, not `uname -m`: inside a Rosetta process
    # uname reports x86_64 even on Apple Silicon, which would skip this block.
    if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]; then
        RETROARCH=( /usr/bin/arch -arm64 "${RETROARCH[0]}" )
        DUCKSTATION=( /usr/bin/arch -arm64 "${DUCKSTATION[0]}" )
        DOLPHIN=( /usr/bin/arch -arm64 "${DOLPHIN[0]}" )
        AZAHAR=( /usr/bin/arch -arm64 "${AZAHAR[0]}" )
        RYUJINX=( /usr/bin/arch -arm64 "${RYUJINX[0]}" )
        VITA3K=( /usr/bin/arch -arm64 "${VITA3K[0]}" )
    fi
elif [[ "$OS" == "Linux" ]]; then
    # Emulators are installed as Flatpaks (see install-linux.sh).
    RETROARCH=( flatpak run org.libretro.RetroArch )
    DUCKSTATION=( flatpak run org.duckstation.DuckStation )
    DOLPHIN=( flatpak run org.DolphinEmu.dolphin-emu )
    AZAHAR=( flatpak run org.azahar_emu.azahar )
    RYUJINX=( flatpak run org.ryujinx.Ryujinx )
    VITA3K=( flatpak run org.vita3k.Vita3K )
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
    3ds)
        exec "${AZAHAR[@]}" -f "$ROM"
        ;;
    switch)
        exec "${RYUJINX[@]}" --fullscreen "$ROM"
        ;;
    psvita|vita)
        # ROM can be a .vita stub containing the Title ID, or named <TitleID>.vita,
        # or a direct path to an installed directory/eboot.
        tid=""
        if [[ -f "$ROM" ]]; then
            tid="$(head -n 1 "$ROM" 2>/dev/null | tr -d '\r\n[:space:]')"
            [[ -n "$tid" ]] || tid="$(basename "$ROM" .vita)"
        else
            tid="$(basename "$ROM")"
            tid="${tid%.*}"
        fi
        exec "${VITA3K[@]}" -r "$tid"
        ;;
    *)
        echo "Unknown system: $SYSTEM" >&2
        echo "Valid systems: snes gbc gba n64 nds psx wii 3ds switch psvita" >&2
        exit 2
        ;;
esac

exec "${RETROARCH[@]}" -L "$CORES_DIR/${core}.${CORE_EXT}" "$ROM"
