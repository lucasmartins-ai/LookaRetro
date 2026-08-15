#!/usr/bin/env bash
# LookaRetro — Pegasus settings actions.
#
# Each "game" in the LookaRetro Config collection inside Pegasus launches this
# script with an action name. Feedback is shown with GUI dialogs (osascript),
# and privileged actions (pmset / launchd) prompt for the admin password via
# the standard macOS dialog — no terminal needed.
#
# Actions:
#   console   -> never-sleep console mode (TV) — re-enables + watchdog
#   sleep     -> restore normal macOS sleep (removes watchdog + timers)
#   n64-turbo -> N64 renderer = ParaLLEl-RDP (Vulkan/GPU, fast)
#   n64-compat-> N64 renderer = Angrylion (software, most compatible)
#   controls  -> re-run controller setup for all emulators
#   refresh   -> regenerate Pegasus game lists (import ROMs + catalog)
set -uo pipefail

ACTION="${1:-help}"
RETRO_HOME="${RETRO_HOME:-$HOME/Retro}"
RA_DIR="$HOME/Library/Application Support/RetroArch"
M64_OPT="$RA_DIR/config/Mupen64Plus-Next/Mupen64Plus-Next.opt"

dialog() {  # $1 = mensagem, $2 = título
    osascript -e "display dialog $(printf '%q' "$1") with title $(printf '%q' "$2") buttons {\"OK\"} default button 1" >/dev/null 2>&1
}

admin() {  # roda o comando com privilégios de administrador (pede senha)
    osascript -e "do shell script $(printf '%q' "$1") with administrator privileges" 2>&1
}

write_opt() {  # $1 = rdp  $2 = rsp
    mkdir -p "$(dirname "$M64_OPT")"
    for kv in "mupen64plus-rdp-plugin=$1" "mupen64plus-rsp-plugin=$2"; do
        key="${kv%%=*}"; val="${kv#*=}"
        if grep -q "^$key" "$M64_OPT" 2>/dev/null; then
            perl -pi -e "s/^$key.*/$key = \"$val\"/" "$M64_OPT"
        else
            printf '%s = "%s"\n' "$key" "$val" >> "$M64_OPT"
        fi
    done
}

case "$ACTION" in
    console)
        PLIST=/tmp/com.lookaretro.never-sleep.plist
        cat > "$PLIST" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.lookaretro.never-sleep</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/pmset</string><string>-a</string>
        <string>disablesleep</string><string>1</string>
        <string>sleep</string><string>0</string>
        <string>disksleep</string><string>0</string>
        <string>displaysleep</string><string>0</string>
        <string>standby</string><string>0</string>
        <string>autopoweroff</string><string>0</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>StartInterval</key><integer>300</integer>
</dict>
</plist>
EOF
        OUT="$(admin "cp -f '$PLIST' /Library/LaunchDaemons/ && launchctl bootout system /Library/LaunchDaemons/com.lookaretro.never-sleep.plist 2>/dev/null; launchctl bootstrap system /Library/LaunchDaemons/com.lookaretro.never-sleep.plist && pmset -a disablesleep 1 sleep 0 disksleep 0 displaysleep 0 standby 0 autopoweroff 0")"
        if [[ -n "$OUT" ]]; then
            dialog "Não foi possível ativar o modo console: $OUT" "LookaRetro — erro"
        else
            dialog "Modo console ativado: o Mac não vai mais dormir (tampa fechada OK). Para reverter, abra “Modo Normal — dormir” aqui no painel." "LookaRetro"
        fi
        ;;
    sleep)
        OUT="$(admin "launchctl bootout system /Library/LaunchDaemons/com.lookaretro.never-sleep.plist 2>/dev/null; rm -f /Library/LaunchDaemons/com.lookaretro.never-sleep.plist; pmset -a disablesleep 0 sleep 10 disksleep 10 displaysleep 10 standby 1 autopoweroff 1")"
        if [[ -n "$OUT" ]]; then
            dialog "Não foi possível restaurar o sleep: $OUT" "LookaRetro — erro"
        else
            dialog "Sleep restaurado (10 min + tampa fechada). Se o Mac não dormir, desconecte os controles Bluetooth (bluetoothd mantém acordado)." "LookaRetro"
        fi
        ;;
    n64-turbo)
        write_opt "parallel" "parallel"
        dialog "N64 em modo Turbo (ParaLLEl-RDP, GPU). Próximo jogo de N64 já usa." "LookaRetro"
        ;;
    n64-compat)
        write_opt "angrylion" "hle"
        dialog "N64 em modo Compatível (Angrylion, software). Próximo jogo de N64 já usa." "LookaRetro"
        ;;
    controls)
        if [[ -f "$RETRO_HOME/scripts/setup-controllers.sh" ]]; then
            bash "$RETRO_HOME/scripts/setup-controllers.sh" >/dev/null 2>&1
            dialog "Controles reconfigurados (P1/P2, Dolphin, DuckStation, N64)." "LookaRetro"
        else
            dialog "setup-controllers.sh não encontrado — rode o update-mac.sh uma vez." "LookaRetro — erro"
        fi
        ;;
    refresh)
        OUT="$(bash "$RETRO_HOME/scripts/import-roms.sh" 2>&1; bash "$RETRO_HOME/scripts/make-open-source-catalog.sh" 2>&1; bash "$RETRO_HOME/scripts/make-settings-catalog.sh" 2>&1)"
        dialog "Listas de jogos atualizadas. Pressione F5 no Pegasus para recarregar." "LookaRetro"
        ;;
    *)
        dialog "Ação desconhecida: $ACTION" "LookaRetro — erro"
        ;;
esac
