# ROMs — legalidade, scraping e alternativas open source

## Aviso legal (leia antes)

A maioria dos jogos que você listou — Zelda, Donkey Kong, Mario, Pokémon, Tekken, Gran Turismo, Street Fighter, Top Gear, Bomberman, Harry Potter, Final Fantasy, Dragon Ball etc. — são **obras comerciais protegidas por copyright**. Elas **não são open source**, e este projeto **não fornece, não aponta para e não ajuda a baixar** essas ROMs.

Para jogar esses títulos legalmente, use **cópias que você mesmo extraiu** dos cartuchos/discos que possui (dump caseiro). Ferramentas comuns: para cartuchos, flashcarts/readers (GBxCart RW, Retrode); para discos de PS1/Wii, um drive de DVD compatível. A legislação varia por país — verifique a sua.

> Resumo: o LookaRetro cuida de **toda a parte técnica** (emuladores, interface, configs). As ROMs comerciais são responsabilidade sua, a partir de mídia própria.

## Catálogo Open Source embutido (download automático)

O instalador cria uma coleção **"Open Source"** no Pegasus com jogos homebrew/open source. Ao clicar em **jogar**, a ROM é **baixada automaticamente da fonte oficial na primeira execução** (depois fica em cache e abre direto).

**Como funciona:**
- Cada jogo começa como um *stub* (arquivo de 0 bytes) em `roms-open-source/`.
- O `launch:` chama `fetch-and-play.sh <sistema> <arquivo> <url>`, que baixa a ROM se ela ainda for stub e então abre o emulador.
- O catálogo é definido em `catalog/open-source.tsv` (uma linha por jogo: `sistema	arquivo	título	autor	licença	url`).

**Jogos incluídos** (todos de releases oficiais no GitHub):

| Jogo | Sistema | Licença |
|---|---|---|
| Adjustris | Game Boy | CC0-1.0 |
| uCity | Game Boy Color | GPL-3.0 |
| Celeste Classic | Game Boy Advance | MIT |
| Space Rescue Squad (Demo) | SNES | open source (demo do autor) |
| Cannons | SNES | MIT |
| Asteroids | SNES | MIT |
| Pong | SNES | MIT |
| Memory Game | SNES | MIT |
| Bat Cave | SNES | MIT |
| Elevator Madness DX | SNES | MIT |
| First Person Tetromones | SNES | MIT |
| Horizontal Shooter | SNES | MIT |
| Falling Tower | SNES | MIT |
| Moonfish (Demo) | Nintendo 64 | open source (demo do autor) |

> ⚠️ **N64:** toda ROM de N64 embute um bootloader não-livre da Nintendo (IPL3), então nenhum homebrew de N64 é 100% livre — ver a [nota da FSF](https://directory.fsf.org/wiki/Collection:Game_ROM_images). O demo Moonfish é incluído por conveniência.

**Adicionar mais jogos:** acrescente uma linha em `catalog/open-source.tsv` e re-rogue:

```bash
# macOS / Linux
~/Retro/scripts/make-open-source-catalog.sh
```
```powershell
# Windows
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Retro\scripts\make-open-source-catalog.ps1"
```

Depois recarregue o Pegasus (F5). A URL pode ser um ROM direto (`.gb`/`.sfc`/`.z64`…) ou um `.zip` (extraído automaticamente).

## Jogos genuinamente open source / homebrew

Estes você pode baixar e usar à vontade (licenças livres). Ótimos para testar o setup:

### SNES
- **Micro Mages** (demo/ROM gratuita do jogo indie, roda em SNES real)
- Homebrew em [snes.nesdev.org](https://snes.nesdev.org) e competições (SNESdev, 32blit)

### Game Boy / Game Boy Color
- **Pokitto / homebrew GB** no [Homebrew Hub](https://hh.gbdev.io) (centenas de ROMs livres p/ GB/GBC)
- **GB Studio** games (o próprio GB Studio publica exemplos)

### Game Boy Advance
- **Celeste Classic** (PICO-8 port p/ GBA, open source)
- Homebrew no [gba.nesdev.org](https://gba.nesdev.org)

### N64
- **libdragon** demos e homebrew do ecossistema libdragon

### DS
- **devkitPro** exemplos e homebrew DS

### PS1
- **PSn00bSDK** e **Nugget** homebrew; demos da cena

### Wii
- **Wii Homebrew** (via devkitPPC), **Yet Another Homebrew Channel**-style demos

Bons indexadores de homebrew: [Homebrew Hub](https://hh.gbdev.io) (GB/GBC), [itch.io](https://itch.io) (filtre por "homebrew"), e fóruns como GBAtemp/RHDN.

## Scraping (capas, capturas, vídeos)

O tema LookaRetro mostra a **boxart** (`assets.boxFront`), **screenshot/background** e **vídeo**, além de título/sinopse. Para preencher isso automaticamente:

### Opção recomendada: Skraper
1. Crie uma conta em [skraper.net](https://www.skraper.net) (grátis).
2. Selecione a pasta `~/Retro/roms/<sistema>` e o sistema correspondente.
3. Escolha os assets: **Box 2D/3D**, **Screenshot**, **Wheel/Logo**, **Video**.
4. Formato de saída: **Pegasus** (o Skraper gera `metadata.pegasus.txt` com as referências).

### Pegando as capas manualmente
O Pegasus procura os assets por convenção de nome, ao lado dos arquivos de mídia do jogo (mesmo nome base):
- `Seu Jogo.png` / `.jpg` → boxart
- `Seu Jogo-boxFront.png` → boxart
- `Seu Jogo-screenshot.png` → screenshot
- `Seu Jogo-background.png` → background
- `Seu Jogo-video.mp4` → vídeo

Ou especifique direto no `metadata.pegasus.txt`:
```
game: Seu Jogo
file: Seu Jogo.sfc
assets.boxFront: capas/seu-jogo.png
assets.screenshot: screens/seu-jogo.png
```

Veja [docs/METADATA.md](METADATA.md) para o formato completo.

## Formatos recomendados por sistema

| Sistema | Preferido | Obs. |
|---|---|---|
| SNES/GBC/GBA | arquivo original (.sfc/.gb/.gba) | já são pequenos |
| N64 | `.z64` (big-endian) | `.n64`/`.v64` também funcionam |
| DS | `.nds` | — |
| PS1 | `.chd` (1 arquivo por jogo, comprimido) | ou `.cue`+`.bin`; `.m3u` p/ multi-discos |
| Wii | `.wbfs` (só o jogo, comprimido) | `.rvz` também; evite `.iso` cheio p/ economizar espaço |

> PS1: `.chd` é o mais prático — converte com `chdman` (vem com o MAME) mantendo um arquivo só por disco.
> Wii: `.wbfs` remove o "lixo" do disco e ocupa muito menos.
