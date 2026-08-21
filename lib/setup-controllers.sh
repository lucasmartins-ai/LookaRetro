#!/usr/bin/env bash
# LookaRetro — configura 2 controles (Xbox Wireless / USB) e o vídeo em todos os
# emuladores (macOS).
#
# Rode no Terminal:
#     bash ~/Downloads/LookaRetro/lib/setup-controllers.sh
#
# O que faz (idempotente):
#   1. RetroArch  : fixa P1 = joypad 0, P2 = joypad 1, driver MFi (Apple Game Controller),
#                   Vulkan (MoltenVK) e menu_swap_ok_cancel=true (Xbox A=OK, B=Cancel).
#   1b. Remaps     : instala remaps libretro com A=Confirmar/Pulo, B=Cancelar/Ataque,
#                   X/Y ergonômicos e LT=Z no N64.
#   2. Dolphin    : GC pads 1-2 (mapeamento explícito SDL) + Wii Remotes emulados 1-2.
#   3. DuckStation: layout DualShock nos pads 1 e 2 com rumble ativo (Cross=A, Circle=B).
#   3b. N64       : opções do core Mupen64Plus-Next (ParaLLEl-RDP / Angrylion).
#   4. Mostra o resumo do modo de uso recomendado.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETRO_HOME="${RETRO_HOME:-$HOME/Retro}"
CONFIG_ROOT="$RETRO_HOME/config"
[[ -f "$CONFIG_ROOT/retroarch.cfg" ]] || CONFIG_ROOT="$REPO/../config"
[[ -f "$CONFIG_ROOT/retroarch.cfg" ]] || CONFIG_ROOT="$REPO/config"

RA_DIR="$HOME/Library/Application Support/RetroArch"
RA_CFG="$RA_DIR/retroarch.cfg"
RA_ACTIVE_CFG="$RA_DIR/config/retroarch.cfg"
DOL_CFG="$HOME/Library/Application Support/Dolphin/Config"
DUCK_CFG="$HOME/Library/Application Support/DuckStation/settings.ini"

c_ok=$'\033[32m'; c_dim=$'\033[2m'; c_warn=$'\033[33m'; c_bold=$'\033[1m'; c_off=$'\033[0m'
info() { printf '%s==>%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_warn" "$c_off" "$*"; }
say()  { printf '%s\n' "$*"; }

RDP_VALUE="parallel"
RSP_VALUE="parallel"
for arg in "$@"; do
    case "$arg" in
        --n64-angrylion) RDP_VALUE="angrylion"; RSP_VALUE="hle" ;;
        --n64-gliden64)  RDP_VALUE="gliden64";  RSP_VALUE="hle" ;;
        *) echo "Opção desconhecida: $arg" >&2; exit 2 ;;
    esac
done

echo ""
info "Controles detectados no sistema:"
system_profiler SPBluetoothDataType 2>/dev/null | grep -A2 "Xbox" | grep -E "Product ID|Address" | head -4 \
    || echo "  (verifique se o controle de Xbox está pareado via Bluetooth)"

# ---------------------------------------------------------------------------
# 1. RetroArch — Configuração principal e drivers
# ---------------------------------------------------------------------------
info "RetroArch: configurando drivers (MFi/Cocoa), Vulkan e slots de controle"
mkdir -p "$RA_DIR/config"

apply_key_to_file() {  # $1 = "chave = valor" $2 = arquivo
    local line="$1" dst="$2" key="${1%% =*}" val="${1#* = }"
    [[ -f "$dst" ]] || touch "$dst"
    if grep -q "^${key} = " "$dst" 2>/dev/null; then
        perl -pi -e "s/^\\Q${key}\\E = .*/${line//\//\\/}/" "$dst"
    else
        printf '%s\n' "$line" >> "$dst"
    fi
}

apply_ra_keys() {
    local target="$1"
    apply_key_to_file 'video_driver = "vulkan"' "$target"
    apply_key_to_file 'audio_driver = "coreaudio"' "$target"
    apply_key_to_file 'input_driver = "cocoa"' "$target"
    apply_key_to_file 'input_joypad_driver = "mfi"' "$target"
    apply_key_to_file 'input_autodetect_enable = "true"' "$target"
    apply_key_to_file 'menu_swap_ok_cancel_buttons = "true"' "$target"
    apply_key_to_file 'auto_remaps_enable = "true"' "$target"
    apply_key_to_file 'input_player1_joypad_index = "0"' "$target"
    apply_key_to_file 'input_player2_joypad_index = "1"' "$target"
    apply_key_to_file 'input_menu_toggle_gamepad_combo = "2"' "$target"
    apply_key_to_file 'quit_on_close_content = "true"' "$target"
    apply_key_to_file 'video_fullscreen = "true"' "$target"
    apply_key_to_file 'video_windowed_fullscreen = "true"' "$target"
}

if [[ -f "$RA_ACTIVE_CFG" ]]; then
    apply_ra_keys "$RA_ACTIVE_CFG"
    info "  config ativa atualizada: $RA_ACTIVE_CFG"
fi
apply_ra_keys "$RA_CFG"
info "  config raiz atualizada: $RA_CFG"

# ---------------------------------------------------------------------------
# 1b. RetroArch — Remaps per-core (Xbox A=Aceitar, B=Cancelar)
# ---------------------------------------------------------------------------
RMAP_SRC="$CONFIG_ROOT/remaps"
RMAP_DST="$RA_DIR/config/remaps"

install_remap() {
    local core="$1"
    local src="$RMAP_SRC/$core/$core.rmp"
    if [[ -f "$src" ]]; then
        mkdir -p "$RMAP_DST/$core" "$RA_DIR/config/$core"
        cp -f "$src" "$RMAP_DST/$core/$core.rmp"
        cp -f "$src" "$RA_DIR/config/$core/$core.rmp"
        info "  remap $core instalado com sucesso"
    else
        warn "  remap ausente em $src"
    fi
}

if [[ -d "$RMAP_SRC" ]]; then
    info "RetroArch: instalando remaps de layout padronizado (A=Confirmar, B=Cancelar)"
    install_remap "Snes9x"
    install_remap "Gambatte"
    install_remap "mGBA"
    install_remap "melonDS"
    install_remap "Mupen64Plus-Next"
else
    warn "pasta $RMAP_SRC não encontrada."
fi

# ---------------------------------------------------------------------------
# 2. Dolphin — GameCube e Wii Remotes para 2 controles de Xbox
# ---------------------------------------------------------------------------
info "Dolphin: instalando mapeamento direto de controles Xbox (GCPad 1-2 + Wiimote 1-2)"
mkdir -p "$DOL_CFG" "$DOL_CFG/Profiles/GCPad" "$DOL_CFG/Profiles/Wiimote"
if [[ -f "$CONFIG_ROOT/dolphin/GCPadNew.ini" ]]; then
    cp -f "$CONFIG_ROOT/dolphin/GCPadNew.ini"  "$DOL_CFG/GCPadNew.ini"
    cp -f "$CONFIG_ROOT/dolphin/GCPadNew.ini"  "$DOL_CFG/Profiles/GCPad/SDL Gamepad.ini"
fi
if [[ -f "$CONFIG_ROOT/dolphin/WiimoteNew.ini" ]]; then
    cp -f "$CONFIG_ROOT/dolphin/WiimoteNew.ini" "$DOL_CFG/WiimoteNew.ini"
fi
info "  Dolphin GCPadNew.ini e WiimoteNew.ini atualizados"

# ---------------------------------------------------------------------------
# 3. DuckStation — DualShock e rumble nos pads 1 e 2
# ---------------------------------------------------------------------------
info "DuckStation: verificando e configurando controle de Xbox nos pads 1-2"
if [[ -f "$DUCK_CFG" ]]; then
    perl -pi -e 's/^Type = AnalogController$/Type = DualShock/' "$DUCK_CFG"
    perl -pi -e 's/^LargeMotor = .*/LargeMotor = SDL-0\/LargeMotor/' "$DUCK_CFG"
    perl -pi -e 's/^SmallMotor = .*/SmallMotor = SDL-0\/SmallMotor/' "$DUCK_CFG"
    info "  DuckStation configurado com DualShock e rumble"
fi

# ---------------------------------------------------------------------------
# 3b. N64 — Opções de renderização do Mupen64Plus-Next
# ---------------------------------------------------------------------------
info "N64: Mupen64Plus-Next RDP=$RDP_VALUE RSP=$RSP_VALUE"
M64_DIR="$RA_DIR/config/Mupen64Plus-Next"
mkdir -p "$M64_DIR"
set_opt() {
    local key="$1" val="$2" file="$3"
    [[ -f "$file" ]] || touch "$file"
    if grep -q "^$key" "$file" 2>/dev/null; then
        perl -pi -e "s/^$key.*/$key = \"$val\"/" "$file"
    else
        printf '%s = "%s"\n' "$key" "$val" >> "$file"
    fi
}
set_opt mupen64plus-rdp-plugin "$RDP_VALUE" "$M64_DIR/Mupen64Plus-Next.opt"
set_opt mupen64plus-rsp-plugin "$RSP_VALUE" "$M64_DIR/Mupen64Plus-Next.opt"
GLOBAL_OPTS="$RA_DIR/config/retroarch-core-options.cfg"
set_opt mupen64plus-rdp-plugin "$RDP_VALUE" "$GLOBAL_OPTS"
set_opt mupen64plus-rsp-plugin "$RSP_VALUE" "$GLOBAL_OPTS"

# ---------------------------------------------------------------------------
# 4. Resumo
# ---------------------------------------------------------------------------
say ""
say "${c_bold}== Configuração de Controles Concluída ==${c_off}"
say "  • Botão A (Verde): Aceitar / Confirmar / Pulo"
say "  • Botão B (Vermelho): Cancelar / Voltar / Ataque"
say "  • Botão X (Azul): Ação secundária / Corrida"
say "  • Botão Y (Amarelo): Menu / Pulo alternativo"
say "  • L3 + R3 (clique nos dois analógicos): Menu do RetroArch (Salvar / Sair)"
say "  • Pegasus Frontend: A = Abrir / Jogar | B = Voltar | LB / RB = Mudar Sistema"
say ""
