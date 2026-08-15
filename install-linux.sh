#!/usr/bin/env bash
# LookaRetro — installer for Linux (turns a PC into a retro console).
#
# Emulators are installed as Flatpaks (distro-agnostic) and Pegasus Frontend
# is the standalone x11-static binary (so it can launch the Flatpak emulators
# via `flatpak run`).
#
# Usage:
#     ./install-linux.sh                 # install everything except system changes
#     ./install-linux.sh --system        # also disable lid-close sleep via logind (sudo)
#     ./install-linux.sh --dry-run       # show what would happen, change nothing
#
# Env vars:
#     RETRO_HOME=~/Games/Retro ./install-linux.sh
set -euo pipefail

RETRO_HOME="${RETRO_HOME:-$HOME/Retro}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APPLY_SYSTEM=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --system)  APPLY_SYSTEM=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

# Version pins
PEGASUS_URL="https://github.com/mmatyas/pegasus-frontend/releases/download/continuous/pegasus-fe_alpha16-105-g6b322063_x11-static.zip"
RETROARCH_CORES_BASE="https://buildbot.libretro.com/nightly/linux/x86_64/latest"

FLATPAK_APPS=(
    org.libretro.RetroArch
    org.duckstation.DuckStation
    org.DolphinEmu.dolphin-emu
)

CORES=(
    snes9x_libretro.so
    gambatte_libretro.so
    mgba_libretro.so
    mupen64plus_next_libretro.so
    melonds_libretro.so
)

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
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# 1. Flatpak + Flathub
# ---------------------------------------------------------------------------
step "Checking Flatpak"
if ! have flatpak; then
    err "Flatpak is required. Install it first, then re-run:"
    err "  Debian/Ubuntu: sudo apt install flatpak && sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    err "  Fedora:        sudo dnf install flatpak"
    err "  Arch:          sudo pacman -S flatpak"
    exit 1
fi
if ! flatpak remotes 2>/dev/null | grep -q flathub; then
    info "Adding Flathub remote..."
    run flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# ---------------------------------------------------------------------------
# 2. Emulators (Flatpak)
# ---------------------------------------------------------------------------
step "Installing RetroArch, DuckStation and Dolphin (Flatpak)"
for app in "${FLATPAK_APPS[@]}"; do
    if flatpak info "$app" >/dev/null 2>&1; then
        info "$app already installed — skipping"
        continue
    fi
    info "Installing $app ..."
    run flatpak install -y --user flathub "$app"
done

# Allow the emulators to read the ROM library.
for app in "${FLATPAK_APPS[@]}"; do
    run flatpak override --user --filesystem=home "$app"
done

# ---------------------------------------------------------------------------
# 3. Pegasus Frontend (standalone x11-static binary)
# ---------------------------------------------------------------------------
step "Installing Pegasus Frontend (standalone binary)"
PEG_DIR="$RETRO_HOME/emulators/Pegasus"
run mkdir -p "$PEG_DIR"
if [[ "$DRY_RUN" -eq 1 ]]; then
    info "Would download $PEGASUS_URL -> $PEG_DIR"
else
    if [[ -f "$PEG_DIR/pegasus-fe" ]]; then
        info "Pegasus already present — skipping"
    else
        TMP_DIR="$(mktemp -d)"
        trap 'rm -rf "$TMP_DIR"' EXIT
        info "Downloading Pegasus..."
        curl -fL --retry 3 -o "$TMP_DIR/pegasus.zip" "$PEGASUS_URL"
        unzip -q -o "$TMP_DIR/pegasus.zip" -d "$PEG_DIR"
        chmod +x "$PEG_DIR/pegasus-fe"
    fi
fi

# ---------------------------------------------------------------------------
# 4. RetroArch cores + config (Flatpak RetroArch)
# ---------------------------------------------------------------------------
step "Installing RetroArch cores + config"
RA_CFG_DIR="$HOME/.var/app/org.libretro.RetroArch/config/retroarch"
CORES_DIR="$RA_CFG_DIR/cores"
run mkdir -p "$CORES_DIR" "$RA_CFG_DIR/config"

for core in "${CORES[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Would download $core"
        continue
    fi
    if [[ -f "$CORES_DIR/$core" ]]; then
        info "$core already present — skipping"
        continue
    fi
    info "Downloading $core ..."
    TMP_DIR="${TMP_DIR:-$(mktemp -d)}"
    curl -fL --retry 3 -o "$TMP_DIR/$core.zip" "$RETROARCH_CORES_BASE/${core}.zip"
    unzip -q -o "$TMP_DIR/$core.zip" -d "$CORES_DIR"
done

if [[ "$DRY_RUN" -eq 0 ]]; then
    if [[ -f "$RA_CFG_DIR/retroarch.cfg" ]]; then
        cp -f "$RA_CFG_DIR/retroarch.cfg" "$RA_CFG_DIR/retroarch.cfg.lookaretro.bak"
    fi
    cat "$REPO_DIR/config/retroarch.cfg" "$REPO_DIR/config/platform/linux.cfg" > "$RA_CFG_DIR/retroarch.cfg"

    # Per-core overrides
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
else
    info "Would write RetroArch config + per-core overrides"
fi

# ---------------------------------------------------------------------------
# 5. Deploy console root + theme + Pegasus config
# ---------------------------------------------------------------------------
step "Deploying scripts, theme and Pegasus config to $RETRO_HOME"
for d in roms scripts config; do run mkdir -p "$RETRO_HOME/$d"; done
for s in snes gbc gba n64 nds psx wii; do run mkdir -p "$RETRO_HOME/roms/$s"; done

run cp -f "$REPO_DIR/lib/launch.sh"      "$RETRO_HOME/scripts/launch.sh"
run cp -f "$REPO_DIR/lib/import-roms.sh" "$RETRO_HOME/scripts/import-roms.sh"
run chmod +x "$RETRO_HOME/scripts/launch.sh" "$RETRO_HOME/scripts/import-roms.sh"

PEG_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus-frontend"
run mkdir -p "$PEG_CFG_DIR/themes/LookaRetro"
run cp -f "$REPO_DIR/theme/LookaRetro/theme.cfg" "$PEG_CFG_DIR/themes/LookaRetro/theme.cfg"
run cp -f "$REPO_DIR/theme/LookaRetro/theme.qml" "$PEG_CFG_DIR/themes/LookaRetro/theme.qml"

if [[ "$DRY_RUN" -eq 0 ]]; then
    cat > "$PEG_CFG_DIR/settings.txt" <<EOF
general.fullscreen: true
general.theme: themes/LookaRetro
EOF
    {
        echo "# LookaRetro game directories"
        for s in snes gbc gba n64 nds psx wii; do
            echo "$RETRO_HOME/roms/$s"
        done
    } > "$PEG_CFG_DIR/game_dirs.txt"
else
    info "Would write $PEG_CFG_DIR/settings.txt + game_dirs.txt"
fi

# ---------------------------------------------------------------------------
# 6. Import existing ROMs
# ---------------------------------------------------------------------------
step "Scanning for ROMs"
run bash "$RETRO_HOME/scripts/import-roms.sh"

# ---------------------------------------------------------------------------
# 7. Persistence: never-sleep (systemd-inhibit) + auto-boot (XDG autostart)
# ---------------------------------------------------------------------------
step "Installing persistence (never-sleep + auto-boot)"
USER_SYSTEMD="$HOME/.config/systemd/user"
AUTOSTART="$HOME/.config/autostart"
run mkdir -p "$USER_SYSTEMD" "$AUTOSTART"

if [[ "$DRY_RUN" -eq 0 ]]; then
    # Never-sleep: a user service holding a systemd-inhibit sleep lock.
    cp -f "$REPO_DIR/systemd/lookaretro-inhibit.service" "$USER_SYSTEMD/lookaretro-inhibit.service"
    systemctl --user daemon-reload
    systemctl --user enable --now lookaretro-inhibit.service

    # Auto-boot: XDG autostart entry launching Pegasus.
    sed -e "s|@PEG_DIR@|$PEG_DIR|g" "$REPO_DIR/systemd/lookaretro-pegasus.desktop" > "$AUTOSTART/lookaretro-pegasus.desktop"
    chmod +x "$AUTOSTART/lookaretro-pegasus.desktop"
else
    info "Would install lookaretro-inhibit.service + lookaretro-pegasus.desktop"
fi

# ---------------------------------------------------------------------------
# 8. Optional: logind lid-close override (root)
# ---------------------------------------------------------------------------
if [[ "$APPLY_SYSTEM" -eq 1 ]]; then
    step "Disabling lid-close sleep via logind (sudo)"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        info "Would write /etc/systemd/logind.conf.d/lookaretro.conf"
    else
        sudo mkdir -p /etc/systemd/logind.conf.d
        sudo cp -f "$REPO_DIR/systemd/lookaretro-logind.conf" /etc/systemd/logind.conf.d/lookaretro.conf
        info "Restarting systemd-logind..."
        sudo systemctl restart systemd-logind
    fi
fi

# ---------------------------------------------------------------------------
say ""
say "${c_bold}LookaRetro — installation summary${c_off}"
say "${c_dim}────────────────────────────────────────${c_off}"
say "Console root:  $RETRO_HOME"
say "Pegasus:       $PEG_DIR/pegasus-fe"
say "Theme:         LookaRetro (auto-selected)"
say "Persistence:   systemd-inhibit (never sleep) + XDG autostart"
if [[ "$APPLY_SYSTEM" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
    say "Lid-close:     ignored (logind override applied)"
else
    say "Lid-close:     NOT overridden — run '$0 --system' to disable lid-close sleep."
fi
say ""
say "${c_bold}Next steps:${c_off}"
say "  1. Drop ROMs into $RETRO_HOME/roms/<system>/ (see docs/ROMS.md)."
say "  2. Re-run:  $RETRO_HOME/scripts/import-roms.sh"
say "  3. Launch:  $PEG_DIR/pegasus-fe   (START on the gamepad opens settings)"
