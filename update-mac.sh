#!/usr/bin/env bash
# LookaRetro — atualiza uma instalação macOS existente + organiza as ROMs.
#
# Rode no Terminal (uma única vez):
#     bash ~/Downloads/LookaRetro/update-mac.sh
#
# O que faz:
#   1. Atualiza scripts, catálogo open source e o tema v1.2.0 (pixel-art + LotR).
#   1b. Corrige o RetroArch: se o build instalado for x86_64 (Rosetta), troca
#       pelo build universal/Metal para os cores arm64 funcionarem (GBA/N64/DS).
#   2. Organiza as ROMs de ~/Retro/roms/ROMs1/ para as pastas certas
#      (snes / n64 / gba / gbc / nds / psx), extraindo os .zip/.7z.
#   3. Regenera as listas de jogos do Pegasus.
#
# É idempotente e não apaga nada: os .zip/.7z originais vão para
# ~/Retro/roms/ROMs1/_originais/ e os arquivos repetidos são ignorados.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="${RETRO_HOME:-$HOME/Retro}"
PEG="${PEG_DIR:-$HOME/Library/Preferences/pegasus-frontend}"
ROM1="$R/roms/ROMs1"

c_ok=$'\033[32m'; c_warn=$'\033[33m'; c_bold=$'\033[1m'; c_off=$'\033[0m'
say()  { printf '%s\n' "$*"; }
step() { printf '\n%s## %s%s\n' "$c_bold" "$*" "$c_off"; }
info() { printf '%s==>%s %s\n' "$c_ok" "$c_off" "$*"; }

# ---------------------------------------------------------------------------
# 1. Atualizar tema + scripts + catálogo
# ---------------------------------------------------------------------------
step "Atualizando tema, scripts e catálogo"
mkdir -p "$R/scripts" "$R/catalog"
cp -f "$REPO/lib/launch.sh" "$REPO/lib/import-roms.sh" \
      "$REPO/lib/fetch-and-play.sh" "$REPO/lib/make-open-source-catalog.sh" \
      "$REPO/lib/make-settings-catalog.sh" "$REPO/lib/pegasus-settings.sh" \
      "$REPO/lib/setup-controllers.sh" \
      "$R/scripts/"
chmod +x "$R/scripts/"*.sh
cp -f "$REPO/catalog/open-source.tsv" "$R/catalog/"

rm -rf "$PEG/themes/LookaRetro"
mkdir -p "$PEG/themes/LookaRetro"
cp -R "$REPO/theme/LookaRetro/." "$PEG/themes/LookaRetro/"
info "tema v1.2.0 instalado"

{
    echo "# LookaRetro game directories"
    for s in snes gbc gba n64 nds psx wii; do echo "$R/roms/$s"; done
    echo "$R/roms-open-source"
    echo "$R/roms-settings"
} > "$PEG/game_dirs.txt"
info "game_dirs.txt atualizado"

# ---------------------------------------------------------------------------
# 1b. Corrigir arquitetura do RetroArch (x86_64 -> universal/Metal)
# ---------------------------------------------------------------------------
if [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == "1" ]]; then
    RA_BIN="/Applications/RetroArch.app/Contents/MacOS/RetroArch"
    if [[ -f "$RA_BIN" ]] && ! file "$RA_BIN" | grep -q "arm64"; then
        step "Corrigindo RetroArch (x86_64 -> build universal/Metal)"
        info "O RetroArch instalado é x86_64 (Rosetta) e NÃO carrega os cores arm64"
        info "baixados do buildbot (erro 'incompatible architecture')."
        info "Trocando pelo build universal/Metal (nativo, sem Rosetta)..."
        if ! command -v brew >/dev/null 2>&1; then
            printf '%s[error]%s Homebrew não encontrado — instale em https://brew.sh e rode de novo.\n' "$c_warn" "$c_off"
        else
            brew uninstall --cask retroarch || true
            brew install --cask retroarch-metal
            info "RetroArch universal instalado. Config e cores foram preservados."
        fi
    else
        info "RetroArch já é universal/arm64 — nada a fazer."
    fi
fi

# ---------------------------------------------------------------------------
# 2. Organizar ROMs
# ---------------------------------------------------------------------------
if [[ ! -d "$ROM1" ]]; then
    info "ROMs1 não encontrado — pulando organização."
else
    step "Organizando ROMs de ROMs1"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    mkdir -p "$R/roms/snes" "$R/roms/n64" "$R/roms/gba" "$R/roms/gbc" \
             "$R/roms/nds" "$R/roms/psx" "$ROM1/_originais"

    moved=0; skipped=0
    place() {  # $1=arquivo $2=pasta-destino
        local base
        base="$(basename "$1")"
        if [[ -e "$2/$base" ]]; then
            skipped=$((skipped+1))
            return
        fi
        mv "$1" "$2/" && moved=$((moved+1))
    }

    ZELDA="$ROM1/legend-of-zelda-the-a-link-to-the-past-usa_202412"
    [[ -d "$ZELDA" ]] || ZELDA="$ROM1"

    # SNES soltos
    while IFS= read -r -d '' f; do place "$f" "$R/roms/snes"; done < <(
        find "$ZELDA" -maxdepth 1 -type f \
            \( -iname '*.sfc' -o -iname '*.smc' -o -iname '*.bs' -o -iname '*.fig' -o -iname '*.swc' \) \
            ! -name '._*' -print0 2>/dev/null || true )

    # SNES em .zip (1 ROM por zip)
    for z in "$ZELDA"/*.zip; do
        [[ -e "$z" ]] || continue
        rm -rf "$TMP/z"; mkdir -p "$TMP/z"
        unzip -q -j -o "$z" -d "$TMP/z" || { say "  [falha] $z"; continue; }
        while IFS= read -r -d '' f; do place "$f" "$R/roms/snes"; done < <(
            find "$TMP/z" -type f \
                \( -iname '*.sfc' -o -iname '*.smc' -o -iname '*.bs' -o -iname '*.fig' -o -iname '*.swc' \) \
                ! -name '._*' -print0 )
        mv "$z" "$ROM1/_originais/"
    done

    # SNES em .7z
    for s in "$ZELDA"/*.7z; do
        [[ -e "$s" ]] || continue
        rm -rf "$TMP/7"; mkdir -p "$TMP/7"
        tar -xf "$s" -C "$TMP/7" || { say "  [falha] $s"; continue; }
        while IFS= read -r -d '' f; do place "$f" "$R/roms/snes"; done < <(
            find "$TMP/7" -type f \( -iname '*.sfc' -o -iname '*.smc' -o -iname '*.bs' \) ! -name '._*' -print0 )
        mv "$s" "$ROM1/_originais/"
    done

    # N64
    while IFS= read -r -d '' f; do place "$f" "$R/roms/n64"; done < <(
        find "$ROM1/N64ROMsPACK" -type f \
            \( -iname '*.z64' -o -iname '*.n64' -o -iname '*.v64' -o -iname '*.ndd' \) \
            ! -name '._*' -print0 2>/dev/null || true )

    # GBA
    while IFS= read -r -d '' f; do place "$f" "$R/roms/gba"; done < <(
        find "$ROM1/gba-roms-pack-romspack" -type f \( -iname '*.gba' -o -iname '*.agb' \) \
            ! -name '._*' -print0 2>/dev/null || true )

    # Pokémon (GB/GBC/GBA/NDS dentro de um .zip)
    PK="$ROM1/pokemon-rom-set-gameboy-nintendo-ds/Pokemon Rom Set (Gameboy - Nintendo DS) .zip"
    if [[ -f "$PK" ]]; then
        rm -rf "$TMP/pk"; mkdir -p "$TMP/pk"
        unzip -q -o "$PK" -d "$TMP/pk"
        while IFS= read -r -d '' f; do place "$f" "$R/roms/gbc"; done < <(
            find "$TMP/pk" -type f \( -iname '*.gb' -o -iname '*.gbc' \) ! -name '._*' -print0 )
        while IFS= read -r -d '' f; do place "$f" "$R/roms/gba"; done < <(
            find "$TMP/pk" -type f -iname '*.gba' ! -name '._*' -print0 )
        while IFS= read -r -d '' f; do place "$f" "$R/roms/nds"; done < <(
            find "$TMP/pk" -type f -iname '*.nds' ! -name '._*' -print0 )
        mv "$PK" "$ROM1/_originais/"
    fi

    # PS1 (pares .cue + .bin completos)
    for cue in "$ROM1"/*.cue; do
        [[ -e "$cue" ]] || continue
        bin="${cue%.cue}.bin"
        if [[ -f "$bin" ]]; then
            place "$cue" "$R/roms/psx"
            place "$bin" "$R/roms/psx"
        else
            say "  [incompleto, ignorado] $(basename "$cue") (sem .bin)"
        fi
    done

    say ""
    say "ROMs movidas: $moved  |  ignoradas (já existiam): $skipped"
fi

# ---------------------------------------------------------------------------
# 3. Regenerar listas
# ---------------------------------------------------------------------------
step "Regenerando listas de jogos"
bash "$R/scripts/import-roms.sh"
bash "$R/scripts/make-open-source-catalog.sh"
bash "$R/scripts/make-settings-catalog.sh"

# ---------------------------------------------------------------------------
# 3b. Configurar os controles em todos os emuladores (P1/P2, Dolphin, DuckStation)
# ---------------------------------------------------------------------------
step "Configurando controles (RetroArch/Dolphin/DuckStation)"
if [[ -f "$REPO/lib/setup-controllers.sh" ]]; then
    bash "$REPO/lib/setup-controllers.sh" || say "  [aviso] setup de controles falhou — rode manualmente: bash $R/scripts/setup-controllers.sh"
else
    say "  [aviso] setup-controllers.sh não encontrado no repo — copie o LookaRetro atualizado."
fi

say ""
say "${c_bold}Pronto!${c_off} Abra o Pegasus.app (Finder ou Dock) — ou pressione F5 nele — para ver os jogos."
