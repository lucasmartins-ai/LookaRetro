#!/usr/bin/env bash
# LookaRetro — reverts the Linux persistence applied by install-linux.sh.
# Does NOT remove the emulators or your ROMs.
#
# Usage:
#     ./uninstall-linux.sh            # dry-run
#     ./uninstall-linux.sh --apply    # actually revert (sudo for the logind part)
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

revert "Stopping and disabling the never-sleep inhibitor" \
    systemctl --user disable --now lookaretro-inhibit.service 2>/dev/null || true

if [[ "$APPLY" -eq 1 ]]; then
    rm -f "$HOME/.config/systemd/user/lookaretro-inhibit.service"
    systemctl --user daemon-reload
    rm -f "$HOME/.config/autostart/lookaretro-pegasus.desktop"
    echo "==> Removed inhibit service + autostart entry"
else
    echo "[dry-run] rm -f ~/.config/systemd/user/lookaretro-inhibit.service"
    echo "[dry-run] rm -f ~/.config/autostart/lookaretro-pegasus.desktop"
fi

revert "Removing logind lid-close override" \
    sudo rm -f /etc/systemd/logind.conf.d/lookaretro.conf

if [[ "$APPLY" -eq 1 ]]; then
    sudo systemctl restart systemd-logind
fi

echo
echo "Done. Emulators, configs and ROMs were left untouched."
