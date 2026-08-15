#!/usr/bin/env bash
# LookaRetro — configura 2 controles (Xbox Wireless) e o vídeo em todos os
# emuladores (macOS).
#
# Rode no Terminal:
#     bash ~/Downloads/LookaRetro/setup-controllers.sh
#
# O que faz (idempotente):
#   1. RetroArch  : fixa P1 = primeiro pad (joypad 0), P2 = segundo (joypad 1).
#   2. Dolphin    : GC pads 1-2 (perfil "SDL Gamepad") + Wii Remotes emulados 1-2.
#   3. DuckStation: ativa rumble (DualShock) nos pads 1 e 2.
#   3b. N64       : troca o renderizador do Mupen64Plus-Next para Angrylion
#       (GLideN64 padrão fica com tela preta no macOS) — via core options (.opt).
#   3c. RetroArch : aplica a tunagem LookaRetro (Metal, fullscreen, hard sync,
#       quit_on_close...) no arquivo de config que o RetroArch REALMENTE usa
#       (config/retroarch.cfg), além da raiz — antes a config ficava inerte.
#   4. Mostra o resumo do modo de uso recomendado.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RA_DIR="$HOME/Library/Application Support/RetroArch"
RA_CFG="$RA_DIR/retroarch.cfg"
RA_ACTIVE_CFG="$RA_DIR/config/retroarch.cfg"
DOL_CFG="$HOME/Library/Application Support/Dolphin/Config"
DUCK_CFG="$HOME/Library/Application Support/DuckStation/settings.ini"

c_ok=$'\033[32m'; c_dim=$'\033[2m'; c_warn=$'\033[33m'; c_off=$'\033[0m'
info() { printf '%s==>%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_warn" "$c_off" "$*"; }

# Renderizador do N64:
#   padrão        = "parallel"   (ParaLLEl-RDP via Vulkan/MoltenVK — GPU, rápido)
#   --n64-angrylion  = angrylion (software — mais compatível, mais lento)
#   --n64-gliden64   = gliden64  (default do core — QUEBRADO no macOS, só p/ teste)
# (macOS não tem dynarec neste core — CPU é sempre Cached Interpreter.)
RDP_VALUE="parallel"
RSP_VALUE="parallel"
for arg in "$@"; do
    case "$arg" in
        --n64-angrylion) RDP_VALUE="angrylion"; RSP_VALUE="hle" ;;
        --n64-gliden64)  RDP_VALUE="gliden64";  RSP_VALUE="hle" ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

echo ""
info "Controles detectados (Bluetooth):"
system_profiler SPBluetoothDataType 2>/dev/null | grep -A2 "Xbox Wireless Controller" | grep -E "Product ID|Address" | head -4 \
    || echo "  (não foi possível listar — confira se os 2 pads estão conectados)"

# ---------------------------------------------------------------------------
# 1. RetroArch — fixar P1/P2 por ordem de conexão
# ---------------------------------------------------------------------------
info "RetroArch: fixando P1 = joypad 0, P2 = joypad 1"
if [[ ! -f "$RA_CFG" ]]; then
    warn "retroarch.cfg não encontrado em $RA_CFG — rode install-macos.sh antes."
else
    apply_key() {  # $1 = "chave = valor"
        local line="$1" key="${1%% =*}"
        if grep -q "^${key} = " "$RA_CFG"; then
            perl -pi -e "s/^\\Q${key}\\E = .*/${line//\//\\/}/" "$RA_CFG"
        else
            printf '%s\n' "$line" >> "$RA_CFG"
        fi
    }
    apply_key 'input_player1_joypad_index = "0"'
    apply_key 'input_player2_joypad_index = "1"'
    info "  retroarch.cfg atualizado (${c_dim}$(grep -c '^input_player[12]_joypad_index' "$RA_CFG") linha(s)${c_off})"
fi

# ---------------------------------------------------------------------------
# 2. Dolphin — GC pads + Wii Remotes emulados para 2 jogadores
# ---------------------------------------------------------------------------
info "Dolphin: instalando configs de controle (GC pads 1-2 + Wiimote emulado 1-2)"
mkdir -p "$DOL_CFG"
cp -f "$REPO/config/dolphin/GCPadNew.ini"  "$DOL_CFG/GCPadNew.ini"
cp -f "$REPO/config/dolphin/WiimoteNew.ini" "$DOL_CFG/WiimoteNew.ini"
info "  GCPadNew.ini + WiimoteNew.ini -> $DOL_CFG"

# ---------------------------------------------------------------------------
# 3. DuckStation — rumble (DualShock) nos pads 1 e 2
# ---------------------------------------------------------------------------
info "DuckStation: ativando DualShock (rumble) nos pads 1-2"
if [[ ! -f "$DUCK_CFG" ]]; then
    warn "settings.ini do DuckStation não encontrado em $DUCK_CFG — abra o DuckStation uma vez e rode de novo."
else
    n="$(grep -c '^Type = AnalogController' "$DUCK_CFG" || true)"
    if [[ "$n" -eq 0 ]]; then
        info "  já está como DualShock ou sem pad — nada a fazer."
    else
        perl -pi -e 's/^Type = AnalogController$/Type = DualShock/' "$DUCK_CFG"
        info "  $n pad(s) alternados para DualShock."
    fi
fi

# ---------------------------------------------------------------------------
# 3b. N64 — renderizador Angrylion (GLideN64 fica preto no macOS)
# ---------------------------------------------------------------------------
info "N64: RDP=$RDP_VALUE RSP=$RSP_VALUE (core options do Mupen64Plus-Next)"
M64_DIR="$RA_DIR/config/Mupen64Plus-Next"
mkdir -p "$M64_DIR"
set_opt() {  # $1 = chave  $2 = valor  $3 = arquivo
    if grep -q "^$1" "$3" 2>/dev/null; then
        perl -pi -e "s/^$1.*/$1 = \"$2\"/" "$3"
    else
        printf '%s = "%s"\n' "$1" "$2" >> "$3"
    fi
}
set_opt mupen64plus-rdp-plugin "$RDP_VALUE" "$M64_DIR/Mupen64Plus-Next.opt"
set_opt mupen64plus-rsp-plugin "$RSP_VALUE" "$M64_DIR/Mupen64Plus-Next.opt"
info "  Mupen64Plus-Next.opt -> $(grep -E '^mupen64plus-(rdp|rsp)-plugin' "$M64_DIR/Mupen64Plus-Next.opt" | tr '\n' ' ')"
# Caminho global (fallback quando o .opt por core ainda não existe)
GLOBAL_OPTS="$RA_DIR/config/retroarch-core-options.cfg"
set_opt mupen64plus-rdp-plugin "$RDP_VALUE" "$GLOBAL_OPTS"
set_opt mupen64plus-rsp-plugin "$RSP_VALUE" "$GLOBAL_OPTS"

# ---------------------------------------------------------------------------
# 3c. RetroArch — aplicar a tunagem LookaRetro no arquivo que ele REALMENTE usa
# ---------------------------------------------------------------------------
apply_config_keys() {  # $1 = arquivo-fonte  $2 = arquivo-alvo
    local src="$1" dst="$2" line key val
    [[ -f "$dst" ]] || touch "$dst"
    while IFS= read -r line; do
        case "$line" in
            ''|\#*) continue ;;
        esac
        key="${line%% = *}"
        val="${line#* = }"
        [[ -z "$key" || -z "$val" ]] && continue
        if grep -q "^${key} = " "$dst"; then
            perl -pi -e "s/^\\Q${key}\\E = .*/${key} = ${val//\//\\/}/" "$dst"
        else
            printf '%s = %s\n' "$key" "$val" >> "$dst"
        fi
    done < "$src"
}

info "RetroArch: ativando tunagem LookaRetro (Metal, fullscreen, hard sync, quit_on_close...)"
if [[ -f "$RA_ACTIVE_CFG" ]]; then
    if [[ -f "$RA_ACTIVE_CFG.lookaretro.bak" ]]; then
        warn "  backup existente mantido: retroarch.cfg.lookaretro.bak"
    else
        cp -f "$RA_ACTIVE_CFG" "$RA_ACTIVE_CFG.lookaretro.bak"
    fi
    apply_config_keys "$REPO/config/retroarch.cfg"      "$RA_ACTIVE_CFG"
    apply_config_keys "$REPO/config/platform/macos.cfg" "$RA_ACTIVE_CFG"
    info "  config ativa aplicada: $RA_ACTIVE_CFG"
else
    warn "  config ativa não encontrada em $RA_ACTIVE_CFG — aplicando apenas na raiz."
fi
# Também na raiz (instalações futuras / primeira execução)
apply_config_keys "$REPO/config/retroarch.cfg"      "$RA_CFG"
apply_config_keys "$REPO/config/platform/macos.cfg" "$RA_CFG"
info "  config raiz aplicada: $RA_CFG"

# ---------------------------------------------------------------------------
# 4. Resumo — modo de uso recomendado
# ---------------------------------------------------------------------------
say() { printf '%s\n' "$*"; }
say ""
say "== Modo de uso (2 jogadores, tudo no controle) =="
say "  • P1 = primeiro pad a conectar (listado 1º no Bluetooth) | P2 = segundo."
say "  • Pegasus (menu): A = abrir/iniciar, B = voltar, L1/R1 = sistema,"
say "    START = menu do Pegasus, F5 (teclado) = recarregar tema."
say "  • RetroArch (SNES/GBC/GBA/N64/DS): L3+R3 = menu; 'Close Content'"
say "    fecha o jogo e volta ao Pegasus. Layout de botões = padrão Nintendo."
say "  • N64 agora usa o renderizador ParaLLEl-RDP (Vulkan/MoltenVK, aceleração"
say "    de GPU — rápido). O GLideN64 padrão fica com tela preta no macOS."
say "    Se um jogo abrir preto, troque para o software renderer Angrylion:"
say "    bash ~/Downloads/LookaRetro/setup-controllers.sh --n64-angrylion"
say "  • DuckStation (PS1): Cross=A, Circle=B, Square=X, Triangle=Y,"
say "    L2/R2 = gatilhos, Select=Back, Start=Start. Rumble ativo."
say "  • Dolphin (Wii/GC): A/B/X/Y no pad; em jogos de Wii o ANALÓGICO"
say "    DIREITO aponta o cursor (IR) e o esquerdo sacode. Jogos com Nunchuk:"
say "    Controllers > Wii Remote > Emulated > Extension."
say ""
say "${c_ok}Pronto!${c_off} Abra o Pegasus e teste com os dois pads."
say "Se algum jogo de N64 continuar sem imagem, rode de novo este script com:"
say "  bash ~/Downloads/LookaRetro/setup-controllers.sh --n64-angrylion   (software, compatível)"
say "  bash ~/Downloads/LookaRetro/setup-controllers.sh --n64-gliden64    (não usar no macOS)"
say ""
say "${c_dim}Dica: se o Pegasus/RetroArch estiver aberto, feche antes de rodar este${c_off}"
say "${c_dim}script — o RetroArch reescreve a config ao sair e pode sobrescrever as mudanças.${c_off}"
