#!/usr/bin/env bash
# LookaRetro — reverts the system-wide "console mode" applied by
# `install.sh --system`. It does NOT remove the emulators or your ROMs.
#
# Usage:
#     ./uninstall.sh            # dry-run: show what would be reverted
#     ./uninstall.sh --apply    # actually revert (sudo)
set -euo pipefail

APPLY=0
for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        -h|--help) echo "Usage: $0 [--apply]"; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

revert() {
    local desc="$1"; shift
    if [[ "$APPLY" -eq 1 ]]; then
        echo "==> $desc"
        "$@"
    else
        echo "[dry-run] $desc -> $*"
    fi
}

revert "Removing LaunchAgent (Pegasus auto-start)" \
    launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist" 2>/dev/null || true

if [[ "$APPLY" -eq 1 ]]; then
    rm -f "$HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist"
    echo "==> Removed $HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist"
else
    echo "[dry-run] rm -f $HOME/Library/LaunchAgents/com.lookaretro.pegasus.plist"
fi

revert "Removing LaunchDaemon (never-sleep watchdog)" \
    sudo launchctl bootout system /Library/LaunchDaemons/com.lookaretro.never-sleep.plist 2>/dev/null || true

if [[ "$APPLY" -eq 1 ]]; then
    sudo rm -f /Library/LaunchDaemons/com.lookaretro.never-sleep.plist
    echo "==> Removed /Library/LaunchDaemons/com.lookaretro.never-sleep.plist"
else
    echo "[dry-run] sudo rm -f /Library/LaunchDaemons/com.lookaretro.never-sleep.plist"
fi

revert "Re-enabling sleep (disablesleep 0)" \
    sudo /usr/bin/pmset -a disablesleep 0

# The installer also zeroed the idle timers (sleep/disksleep/displaysleep 0,
# standby/autopoweroff 0) — restore macOS-standard values, otherwise the Mac
# still never sleeps on its own.
revert "Restoring standard sleep timers (10 min idle, standby on)" \
    sudo /usr/bin/pmset -a sleep 10 disksleep 10 displaysleep 10 standby 1 autopoweroff 1

echo
echo "Done. Emulators, configs and ROMs were left untouched."
