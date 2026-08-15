#!/usr/bin/env bash
# LookaRetro — installer for turning an Apple Silicon Mac into a retro console.
#
# What it does (all idempotent — safe to re-run):
#   1. Installs RetroArch + Dolphin via Homebrew (casks).
#   2. Downloads DuckStation (PS1) and Pegasus Frontend (UI) from GitHub.
#   3. Downloads the RetroArch libretro cores for SNES/GBC/GBA/N64/DS.
#   4. Deploys low-latency configs, the launcher, the ROM importer and the
#      custom "LookaRetro" Pegasus theme into $RETRO_HOME (default ~/Retro).
#   5. Wires Pegasus up to the ROM library (settings.txt + game_dirs.txt).
#   6. Generates metadata for any ROMs you already dropped in.
#
# System-wide "console mode" is opt-in (requires sudo):
#     ./install-macos.sh --system
#   -> additionally sets "never sleep" (incl. lid closed) via pmset and
#      installs launchd jobs so the Mac boots straight into Pegasus.
#
# Usage:
#     ./install-macos.sh                 # install everything except system changes
#     ./install-macos.sh --system        # also apply pmset + launchd (sudo)
#     ./install-macos.sh --dry-run       # show what would happen, change nothing
#
# Env vars:
#     RETRO_HOME=~/Games/Retro ./install.sh   # custom console root
set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
RETRO_HOME="${RETRO_HOME:-$HOME/Retro}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APPLY_SYSTEM=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --system)   APPLY_SYSTEM=1 ;;
        --dry-run)  DRY_RUN=1 ;;
        -h|--help)  sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

# Version pins (known-good macOS builds)
PEGASUS_URL="https://github.com/mmatyas/pegasus-frontend/releases/download/weekly_2024w38/pegasus-fe_alpha16-82-gc3462e68_macos-static.zip"
DUCKSTATION_URL="https://github.com/stenzek/duckstation/releases/latest/download/duckstation-mac-release.zip"
RETROARCH_CORES_BASE="https://buildbot.libretro.com/nightly/apple/osx/arm64/latest"

CORES=(
    snes9x_libretro.dylib
    gambatte_libretro.dylib
    mgba_libretro.dylib
    mupen64plus_next_libretro.dylib
    melonds_libretro.dylib
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
c_ok=$'\033[32m'; c_dim=$'\033[2m'; c_warn=$'\033[33m'; c_err=$'\033[31m'; c_bold=$'\033[1m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
info() { printf '%s==>%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_warn" "$c_off" "$*"; }
err()  { printf '%s[error]%s %s\n' "$c_err" "$c_off" "$*"; }
step() { printf '\n%s## %s%s\n' "$c_bold" "$*" "$c_off"; }

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '%s[skip]%s %s\n' "$c_dim" "$c_off" "$*"
        return 0
    fi
    "$@"
}

arch_ok()   { [[ "$(uname -m)" == "arm64" ]]; }
rosetta_ok() { pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
if ! arch_ok; then
    warn "This installer targets Apple Silicon (arm64). Detected: $(uname -m)."
    warn "Emulators may still work, but the prebuilt cores below are arm64-only."
fi

if ! have brew; then
    err "Homebrew not found. Install it first: https://brew.sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. RetroArch + Dolphin (Homebrew casks)
# ---------------------------------------------------------------------------
step "Installing RetroArch and Dolphin (Homebrew casks)"
run brew install --cask retroarch dolphin

# ---------------------------------------------------------------------------
# 2. DuckStation + Pegasus (direct downloads, universal/macOS builds)
# ---------------------------------------------------------------------------
step "Installing DuckStation (PS1) and Pegasus Frontend (UI)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

install_from_zip() {
    local url="$1" appname="$2" binary_hint="$3"
    local zip="$TMP_DIR/$(basename "$url")"
    info "Downloading $appname..."
    run curl -fL --retry 3 -o "$zip" "$url"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Would extract and install $appname -> /Applications"
        return 0
    fi
    run unzip -q -o "$zip" -d "$TMP_DIR/$appname"
    local app
    app="$(find "$TMP_DIR/$appname" -maxdepth 2 -name "*.app" -print -quit)"
    if [[ -z "$app" ]]; then
        err "Could not find the .app bundle in $url"
        return 1
    fi
    if [[ -d "/Applications/$appname.app" ]]; then
        info "Replacing existing /Applications/$appname.app"
        rm -rf "/Applications/$appname.app"
    fi
    ditto "$app" "/Applications/$appname.app"
    info "$appname installed."
}

install_from_zip "$DUCKSTATION_URL" "DuckStation" "DuckStation"

# Pegasus macOS build is x86_64 -> needs Rosetta 2 on Apple Silicon.
if arch_ok && ! rosetta_ok; then
    warn "Rosetta 2 is required to run Pegasus Frontend (its macOS build is x86_64)."
    if [[ "$DRY_RUN" -eq 0 ]]; then
        info "Installing Rosetta 2 (no admin password needed)..."
        softwareupdate --install-rosetta --agree-to-license || warn "Rosetta install failed; you can also run it manually."
    fi
fi
install_from_zip "$PEGASUS_URL" "Pegasus" "pegasus-fe"

# ---------------------------------------------------------------------------
# 3. RetroArch cores
# ---------------------------------------------------------------------------
step "Downloading RetroArch cores (SNES/GBC/GBA/N64/DS)"
CORES_DIR="$HOME/Library/Application Support/RetroArch/cores"
run mkdir -p "$CORES_DIR"
for core in "${CORES[@]}"; do
    url="$RETROARCH_CORES_BASE/${core}.zip"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Would download $url"
        continue
    fi
    if [[ -f "$CORES_DIR/$core" ]]; then
        info "$core already present — skipping"
        continue
    fi
    info "Downloading $core ..."
    run curl -fL --retry 3 -o "$TMP_DIR/$core.zip" "$url"
    run unzip -q -o "$TMP_DIR/$core.zip" -d "$CORES_DIR"
done

# ---------------------------------------------------------------------------
# 4. Deploy console root
# ---------------------------------------------------------------------------
step "Deploying configs, scripts and theme to $RETRO_HOME"
for d in roms scripts config/cores config/dolphin; do
    run mkdir -p "$RETRO_HOME/$d"
done
for s in snes gbc gba n64 nds psx wii; do
    run mkdir -p "$RETRO_HOME/roms/$s"
done

run cp -f "$REPO_DIR/lib/launch.sh"       "$RETRO_HOME/scripts/launch.sh"
run cp -f "$REPO_DIR/lib/import-roms.sh"  "$RETRO_HOME/scripts/import-roms.sh"
run chmod +x "$RETRO_HOME/scripts/launch.sh" "$RETRO_HOME/scripts/import-roms.sh"

run cp -f "$REPO_DIR/config/retroarch.cfg" "$RETRO_HOME/config/retroarch.cfg"
run cp -f "$REPO_DIR/config/cores/"*.cfg    "$RETRO_HOME/config/cores/"
run cp -f "$REPO_DIR/config/dolphin/GFX.ini" "$RETRO_HOME/config/dolphin/GFX.ini"

# Pegasus theme
PEGASUS_CFG_DIR="$HOME/Library/Preferences/pegasus-frontend"
run mkdir -p "$PEGASUS_CFG_DIR/themes/LookaRetro"
run cp -f "$REPO_DIR/theme/LookaRetro/theme.cfg" "$PEGASUS_CFG_DIR/themes/LookaRetro/theme.cfg"
run cp -f "$REPO_DIR/theme/LookaRetro/theme.qml" "$PEGASUS_CFG_DIR/themes/LookaRetro/theme.qml"

# ---------------------------------------------------------------------------
# 5. Wire Pegasus to the ROM library
# ---------------------------------------------------------------------------
step "Configuring Pegasus Frontend"
run mkdir -p "$PEGASUS_CFG_DIR"

# settings.txt: enable fullscreen + select the LookaRetro theme
if [[ "$DRY_RUN" -eq 0 ]]; then
    cat > "$PEGASUS_CFG_DIR/settings.txt" <<EOF
general.fullscreen: true
general.theme: themes/LookaRetro
EOF
else
    info "Would write $PEGASUS_CFG_DIR/settings.txt"
fi

# game_dirs.txt: one ROM directory per line
if [[ "$DRY_RUN" -eq 0 ]]; then
    {
        echo "# LookaRetro game directories"
        for s in snes gbc gba n64 nds psx wii; do
            echo "$RETRO_HOME/roms/$s"
        done
    } > "$PEGASUS_CFG_DIR/game_dirs.txt"
else
    info "Would write $PEGASUS_CFG_DIR/game_dirs.txt"
fi

# ---------------------------------------------------------------------------
# 6. Apply emulator configs (RetroArch + Dolphin) to their real locations
# ---------------------------------------------------------------------------
step "Applying emulator configs"
RA_CFG_DIR="$HOME/Library/Application Support/RetroArch"
run mkdir -p "$RA_CFG_DIR/config"
if [[ "$DRY_RUN" -eq 0 ]]; then
    if [[ -f "$RA_CFG_DIR/retroarch.cfg" ]]; then
        warn "RetroArch config exists — backing up to retroarch.cfg.lookaretro.bak"
        cp -f "$RA_CFG_DIR/retroarch.cfg" "$RA_CFG_DIR/retroarch.cfg.lookaretro.bak"
    fi
    # RetroArch config = shared + macOS driver snippet
    cat "$REPO_DIR/config/retroarch.cfg" "$REPO_DIR/config/platform/macos.cfg" > "$RA_CFG_DIR/retroarch.cfg"

    # Per-core overrides: config/<Core>/<Core>.cfg
    install_override() {
        local corename="$1" src="$2"
        mkdir -p "$RA_CFG_DIR/config/$corename"
        cp -f "$REPO_DIR/config/cores/$src" "$RA_CFG_DIR/config/$corename/$corename.cfg"
    }
    install_override "Snes9x"            "snes9x.cfg"
    install_override "Gambatte"          "gambatte.cfg"
    install_override "mGBA"              "mgba.cfg"
    install_override "melonDS"           "melonds.cfg"
    install_override "Mupen64Plus-Next"  "mupen64plus_next.cfg"

    # Dolphin: minimal GFX.ini with fullscreen enabled
    DOLPHIN_CFG_DIR="$HOME/Library/Application Support/Dolphin/Config"
    mkdir -p "$DOLPHIN_CFG_DIR"
    if [[ -f "$DOLPHIN_CFG_DIR/GFX.ini" ]]; then
        cp -f "$DOLPHIN_CFG_DIR/GFX.ini" "$DOLPHIN_CFG_DIR/GFX.ini.lookaretro.bak"
    fi
    cp -f "$REPO_DIR/config/dolphin/GFX.ini" "$DOLPHIN_CFG_DIR/GFX.ini"
else
    info "Would write RetroArch config + per-core overrides + Dolphin GFX.ini"
fi

# ---------------------------------------------------------------------------
# 7. Import existing ROMs (generates metadata)
# ---------------------------------------------------------------------------
step "Scanning for ROMs"
run bash "$RETRO_HOME/scripts/import-roms.sh"

# ---------------------------------------------------------------------------
# 8. Optional system-wide "console mode"
# ---------------------------------------------------------------------------
if [[ "$APPLY_SYSTEM" -eq 1 ]]; then
    step "Applying system-wide console mode (pmset + launchd)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Would run: sudo pmset -a disablesleep 1 sleep 0 disksleep 0 displaysleep 0 standby 0 autopoweroff 0"
        info "Would install launchd plists (never-sleep daemon + Pegasus agent)"
    else
        info "Disabling sleep (including lid-close) — this keeps the console running with the lid shut."
        sudo /usr/bin/pmset -a disablesleep 1 sleep 0 disksleep 0 displaysleep 0 standby 0 autopoweroff 0

        info "Installing LaunchDaemon (never-sleep watchdog)..."
        sudo cp -f "$REPO_DIR/launchd/com.lookaretro.never-sleep.plist" /Library/LaunchDaemons/
        sudo chown root:wheel /Library/LaunchDaemons/com.lookaretro.never-sleep.plist
        sudo chmod 644 /Library/LaunchDaemons/com.lookaretro.never-sleep.plist
        sudo launchctl bootstrap system /Library/LaunchDaemons/com.lookaretro.never-sleep.plist 2>/dev/null \
            || sudo launchctl load -w /Library/LaunchDaemons/com.lookaretro.never-sleep.plist

        info "Installing LaunchAgent (auto-start Pegasus at login)..."
        mkdir -p "$HOME/Library/LaunchAgents"
        cp -f "$REPO_DIR/launchd/com.lookaretro.pegasus.plist" "$HOME/Library/LaunchAgents/"
        launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist" 2>/dev/null || true
        launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
say ""
say "${c_bold}LookaRetro — installation summary${c_off}"
say "${c_dim}────────────────────────────────────────${c_off}"
say "Console root:   $RETRO_HOME"
say "ROMs:           $RETRO_HOME/roms/<system>/"
say "Launcher:       $RETRO_HOME/scripts/launch.sh"
say "ROM importer:   $RETRO_HOME/scripts/import-roms.sh"
say "Pegasus theme:  LookaRetro (auto-selected)"
if [[ "$APPLY_SYSTEM" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
    say "Console mode:   enabled (never-sleep + auto-boot into Pegasus)"
else
    say "Console mode:   NOT applied — run '$0 --system' to enable never-sleep + auto-boot."
fi
say ""
say "${c_bold}Next steps:${c_off}"
say "  1. Drop your ROMs into $RETRO_HOME/roms/<system>/"
say "     (see docs/ROMS.md — commercial games must come from your own dumps)."
say "  2. Re-run:  $RETRO_HOME/scripts/import-roms.sh"
say "  3. Configure controllers (docs/CONTROLS.md)."
say "  4. Launch Pegasus and enjoy. START (gamepad) opens the settings menu."
